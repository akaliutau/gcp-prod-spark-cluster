# About

These templates setup a Grade I-level production environment for the Spark cluster.

Cluster can be used to run ML/HPC/DS workload, to perform rapid calculations on demand, etc

# Background

Apache Spark is a general-purpose data processing tool. 
It's heavily used by data engineers and data scientists to perform fast data queries on large amounts of data in the terabyte range. 
It competes with the classic Hadoop Map / Reduce by using the RAM available in the cluster for faster execution of jobs. 
The next evolutionary generation of Apache Spark is Apache Beam.


# Prerequisites: set Environment vars

The GCP project ID is auto-configured from the `GOOGLE_CLOUD_PROJECT` environment variable, among several other sources. 

The OAuth2 credentials are auto-configured from the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

This var can be set manually after auto-generating json with google account credentials:

```
gcloud auth application-default login
```


The path to gcloud creds usually has the form:

```
/$HOME/.config/gcloud/legacy_credentials/$EMAIL/adc.json
```

where variable $EMAIL can be obtained via command:

```
gcloud config list account --format "value(core.account)"
```

The tip of the day: 
Add `GOOGLE_APPLICATION_CREDENTIALS` as permanent variable to `/etc/environment` file:

```
sudo -H gedit /etc/environment
```

# Prerequisites: install local Spark environment for testing/debugging

(1) Find the latest stable Spark distributive at [Spark official website](https://spark.apache.org/downloads.html)
We are going to use Spark 3.2.2 + Scala 2.13 (Note the tie Spark<->Scala, this is because Spark has a dependency on Scala)
Note, this should _match_ the version you set in your pom

In this case we are going to download and use 
[spark-3.2.2-bin-hadoop3.2-scala2.13.tgz](https://www.apache.org/dyn/closer.lua/spark/spark-3.2.2/spark-3.2.2-bin-hadoop3.2-scala2.13.tgz)

(2) Download it to local tmp folder and check sha sums:

```bash
cd ~
wget https://dlcdn.apache.org/spark/spark-3.2.2/spark-3.2.2-bin-hadoop3.2-scala2.13.tgz
wget https://downloads.apache.org/spark/spark-3.2.2/spark-3.2.2-bin-hadoop3.2-scala2.13.tgz.sha512
sha512sum spark-3.2.2-bin-hadoop3.2-scala2.13.tgz
cat spark-3.2.2-bin-hadoop3.2-scala2.13.tgz.sha512
```

(3) Extract Spark to /opt

```bash
sudo mkdir /opt/spark
sudo tar -xf spark*.tgz -C /opt/spark --strip-component 1
sudo chmod -R 777 /opt/spark
```

check the installation:

```bash
/opt/spark/bin/spark-shell --version
```

Here one can find all available commands that you can run locally: 

```bash
ls /opt/spark/bin/
``` 

Note: as we have moved files to /opt directory, we have to run the Spark command in the terminal from `/opt/spark`

To change it, one can add all spark folder to the system path:

```bash
echo "export SPARK_HOME=/opt/spark" >> ~/.bashrc
echo "export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin" >> ~/.bashrc
echo "export PYSPARK_PYTHON=/usr/bin/python3" >> ~/.bashrc

source ~/.bashrc
```

# Build and run workload job locally

```bash
mvn clean package
/opt/spark/bin/spark-submit --class net.ddp.mapreduce.PiComputeApp ./spark-core/target/spark-core-1.0-SNAPSHOT.jar
```
The output of last command (which actually the one that runs job) should contain the line:

```bash
...
22/07/18 12:28:31 INFO DAGScheduler: Job 0 finished: reduce at PiComputeApp.java:93, took 1.640840 s
22/07/18 12:28:31 INFO PiComputeApp: Analyzing result in 3685 ms
22/07/18 12:28:31 INFO PiComputeApp: Pi is roughly 3.14034
...
```

# Create cloud infrastructure to run Spark workload in the cloud

Default images available to run your jobs may not support the Run Time you need (f.e. Java 11, 17, etc)
This problem can be solved with the help of _custom images_

(1) To build a custom image to run Java11 workload we start from the following command
(as written in guide https://cloud.google.com/dataproc/docs/guides/dataproc-images#rest-api)

```bash
git clone https://github.com/GoogleCloudDataproc/custom-images
```

and then from the root directory run the script generate_custom_image (choose some existing gcs bucket to hold the image, 
in our case it's gs://dataproc-cluster-custom-images):

```bash
python3 generate_custom_image.py \
    --image-name "custom-debian10-java11" \
    --dataproc-version "2.0-debian10" \
    --disk-size 30 \
    --customization-script <path to terraform/data/custom-image.sh> \
    --zone "us-central1-a" \
    --gcs-bucket "gs://dataproc-cluster-custom-images" \
    --shutdown-instance-timer-sec 500
```
After finishing check that the image  was successfully created:

```bash
gcloud compute images list --filter="name=('custom-debian10-java11')"
gcloud compute images describe custom-debian10-java11
```

(2) Set the `image_version` var in `vars.tf` to that extracted from the output of last command:

```bash
...
labels:
  goog-dataproc-version: 2-0-49-debian10
licenseCodes:
- '1001006'
licenses:
- https://www.googleapis.com/compute/v1/projects/cloud-dataproc/global/licenses/dataproc
name: custom-debian10-java11
...
```

(3) Install Terraform:

```bash
sudo -v
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform=1.3.3
```

(4) Enable Dataproc

```bash
gcloud services enable dataproc
```

(5) Create infrastructure using Terraform:

```
export TF_VAR_google_app_creds=$GOOGLE_APPLICATION_CREDENTIALS
export TF_VAR_project=$GOOGLE_CLOUD_PROJECT
```
(6) Run `terraform init` to download the latest version of the provider and build the `.terraform` directory

```
terraform init
terraform plan
terraform apply
```
# Build and run workload job in the cloud (at Dataproc)

Here is an example of command to run uber jar on Dataproc cluster

First, compiled uber job has to be uploaded to GCS, as cloud spark cannot run it directly

```bash
gsutil cp ./spark-core/target/spark-core-1.0-SNAPSHOT.jar gs://dataproc-cluster-0/spark-core-1.0-SNAPSHOT.jar
```

and then the final command:

```bash
gcloud dataproc jobs submit spark \
    --cluster=dataproc-cluster-0-7f7a78317a21a70a \
    --region=us-central1 \
    --class=net.ddp.mapreduce.PiComputeApp \
    --jars=gs://dataproc-cluster-0/spark-core-1.0-SNAPSHOT.jar \
    -- 1000
```

The job should succeed and show the output similar to we saw earlier

# Appendix I

Remote connection to master node can be done via command:


```bash
gcloud compute ssh --zone "us-central1-c" "dataproc-cluster-0-7f7a78317a21a70a-m"  --tunnel-through-iap --project <project name>
```

To increase the performance of the tunnel, consider installing NumPy. To install NumPy, see: https://numpy.org/install/.
After installing NumPy, run the following command to allow `gcloud` to access  external packages: `export CLOUDSDK_PYTHON_SITEPACKAGES=1`