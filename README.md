[![Build Status](https://travis-ci.org/IBM/kubernetes-container-service-wordpress-deployment.svg?branch=master)](https://travis-ci.org/IBM/kubernetes-container-service-wordpress-deployment)


[![Create Toolchain](https://console.ng.bluemix.net/devops/graphics/create_toolchain_button.png)](https://console.ng.bluemix.net/devops/setup/deploy/?repository=https://github.com/Tomcli/default-toolchain-1491841559208)


# Scalable WordPress deployment on Bluemix Container Service using Kubernetes

This project demonstrates how to deploy WordPress and MySQL on Kubernetes cluster with the capability of IBM Bluemix Container Service. The WordPress uses MySQL as the backend and stores sensitive data into the persistent disks.

WordPress represents a typical multi-tier app and each component will have its own container(s). The WordPress containers will be the frontend tier and the MySQL container will be the database/backend tier for WordPress.

With IBM Bluemix Container Service, you can deploy and manage your own Kubernetes cluster in the cloud that lets you automate the deployment, operation, scaling, and monitoring of containerized apps over a cluster of independent compute hosts called worker nodes.

![kube-wordpress](images/kube-wordpress.png)
 
## Included Components
- Bluemix container service
- Kubernetes
- WordPress
- MySQL

## Prerequisite

Create a Kubernetes cluster with IBM Bluemix Container Service. 

If you have not setup the Kubernetes cluster, please follow the [Creating a Kubernetes cluster](https://github.com/IBM/container-journey-template) tutorial.

## References
- This WordPress example is based on Kubernetes's open source example "mysql-wordpress-pd" at <https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd>

## Objectives

This scenario provides instructions for the following tasks:

- Create local persistent volumes to define persistent disks.
- Create a secret to protect sensitive data.
- Create and deploy the WordPress frontend with one or more pods.
- Create and deploy the MySQL database(using Bluemix MySQL as backend).

## Steps
1. [Setup Secrets](#1-setup-secrets)
2. [Create Services and Deployments](#2-create-services-and-deployments)
3. [Accessing the External Link](#3-accessing-the-external-link)
4. [Using WordPress](#4-using-wordpress)

# 1. Setup Secrets

> *Quickstart option:* In this repository, run `bash scripts/quickstart.sh`.

Create a new file called `password.txt` in the same directory and put your desired MySQL password inside `password.txt` (Could be any string with ASCII characters).


We need to make sure `password.txt` does not have any trailing newline. Use the following command to remove possible newlines.

```bash
tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt
```

# 2. Create Services and Deployments

> *Note:* If you want to use Bluemix Compose-MySql as your backend, please go to [Using Bluemix MySQL as backend](#21-using-bluemix-mysql-as-backend).

Install persistent volume on your cluster's local storage. Then, create the secret and services for MySQL and WordPress.

```bash
kubectl create -f local-volumes.yaml
kubectl create secret generic mysql-pass --from-file=password.txt
kubectl create -f mysql-deployment.yaml
kubectl create -f wordpress-deployment.yaml
```


When all your pods are running, run the following commands to check your pod names.

```bash
kubectl get pods
```

This should return a list of pods from the kubernetes cluster.

```bash
NAME                               READY     STATUS    RESTARTS   AGE
wordpress-3772071710-58mmd         1/1       Running   0          17s
wordpress-mysql-2569670970-bd07b   1/1       Running   0          1m
```

# 2.1 Using Bluemix MySQL as backend

Provision Compose for MySQL in Bluemix via https://console.ng.bluemix.net/catalog/services/compose-for-mysql

Go to Service credentials and view your credentials. Your MySQL hostname, port, user, and password are under your credential url and it should look like this

![mysql](images/mysql.png)

Modify your `wordpress-deployment.yaml` file, change WORDPRESS_DB_HOST's value to your MySQL hostname and port(i.e. `value: <hostname>:<port>`), WORDPRESS_DB_USER's value to your MySQL user, and WORDPRESS_DB_PASSWORD's value to your MySQL password.

And the environment variables should look like this

```yaml
    spec:
      containers:
      - image: wordpress:4.7.3-apache
        name: wordpress
        env:
        - name: WORDPRESS_DB_HOST
          value: sl-us-dal-9-portal.7.dblayer.com:22412
        - name: WORDPRESS_DB_USER
          value: admin
        - name: WORDPRESS_DB_PASSWORD
          value: XMRXTOXTDWOOPXEE
```

After you modified the `wordpress-deployment.yaml`, run the following commands to deploy wordpress.

```bash
kubectl create -f local-volumes.yaml
kubectl create -f wordpress-deployment.yaml
```

When all your pods are running, run the following commands to check your pod names.

```bash
kubectl get pods
```

This should return a list of pods from the kubernetes cluster.

```bash
NAME                               READY     STATUS    RESTARTS   AGE
wordpress-3772071710-58mmd         1/1       Running   0          17s
```
    
# 3. Accessing the External Link 

>(Paid Account Only!!) If you have a paid account, you can create a LoadBalancer by running 
>
>`kubectl edit services wordpress`
>
> Under `spec`, change `type: NodePort` to `type: LoadBalancer`
>
> **Note:** Make sure you have `service "wordpress" edited` shown after editing the yaml file because that means the yaml file is successfully edited without any typo or connection errors.

You can obtain your cluster's IP address using

```bash
$ kubectl get nodes
NAME             STATUS    AGE
169.47.220.142   Ready     23h
```

You will also need to run the following command to get your NodePort number.

```bash
$ kubectl get svc wordpress 
NAME        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
wordpress   10.10.10.57   <nodes>       80:32340/TCP   2m
```

Congratulation. Now you can use the link **http://[IP]:[port number]** to access your WordPress site.


> **Note:** For the above example, the link would be http://169.47.220.142:32340

You can check the status of your deployment on Kubernetes UI. Run 'kubectl proxy' and go to URL 'http://127.0.0.1:8001/ui' to check when the WordPress container becomes ready.

![Kubernetes Status Page](images/kube_ui.png)

> **Note:** It can take up to 5 minutes for the pods to be fully functioning.
    


**(Optional)** If you have more resources in your cluster, and you want to scale up your WordPress website, you can run the following commands to check your current deployments.
```bash
$ kubectl get deployments
NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
wordpress         1         1         1            1           23h
wordpress-mysql   1         1         1            1           23h
```

Now, you can run the following commands to scale up for WordPress frontend.
```bash
$ kubectl scale deployments/wordpress --replicas=2
deployment "wordpress" scaled
$ kubectl get deployments
NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
wordpress         2         2         2            2           23h
wordpress-mysql   1         1         1            1           23h
```
As you can see, we now have 2 pods that are running the WordPress frontend. 

> **Note:** If you are a free tier user, we recommend you only scale up to 10 pods since free tier users have limited resources.

# 4. Using WordPress

Now that WordPress is running you can register as a new user and install WordPress.

![wordpress home Page](images/wordpress.png)

After installing WordPress, you can post new comments.

![wordpress comment Page](images/wordpress_comment.png)




# Troubleshooting

If you accidentally created a password with newlines and you can not authorize your MySQL service, you can delete your current secret using

```bash
kubectl delete secret mysql-pass
```

If you want to delete your services, deployments, and persistent volume claim, you can run
```bash
kubectl delete deployment,service,pvc -l app=wordpress
```

If you want to delete your persistent volume, you can run the following commands
```bash
kubectl delete pv local-volume-1 local-volume-2
```


# License
[Apache 2.0](LICENSE)
