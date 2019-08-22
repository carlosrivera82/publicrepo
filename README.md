I've created the ARM templates for the technical assessment. I couldn't create an App Services Environment for load balancing the App in PaaS mode due to limitations of the Azure Free Trial account I used.

There's a file called deployment.ps1 with all the powershell cmdlets used to deploy the templates. There's a couple of manual actions to take during the process, one creating the Azure Data Lake file system and file share and the other is adding the system managed Id of the Web App to the Key Vault access policies.
To create a file system, browse to the created storage account, select File Systems under Data Lake Storage and add a file system named fswebapptest
To create a file share, select Files under File service and add a file share named webapptestshare
To create an access policy, browse to the created key vault, select Access Policies and an access policy with GET permissions for keys and secrets add the id created for the SentiaCRwebapptest web app

Time total used for the test: About 7 hours
Creating VM network, NSG and Load Balancer: 30 minutes
Creating Storage account, Azure CLI script to add storage to web app: Nearly 1 hour
Customize VM templates to specify disk and nic names: Nearly 1 hour
Creating Web App, research into ASE, enabling key vault and storage services for the app: 4 hours

Design considerations:
To simplify the deployment, I've considered a deployment on a Virtual network called Frontend which houses VMs and web apps facing the internet behind a Network Security Group and/or Azure Load Balancer or App Services Environment load balancing.
The storage and key vault resources don't have firewall configured but in a real environment, they should be configured and being able to be accessed only on the frontend and a backend Virtual network (Such as a VM for management/terminal services/data transfer betweeen On Premises Data Center)
