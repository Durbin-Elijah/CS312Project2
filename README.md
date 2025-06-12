In this project, we run a minecraft server on AWS using terraform, bypassing the need for the AWS dashboard.

In order to achieve these project goals, you will need these programs installed

Terraform 1.12.2
AWS CLI version 2

The first step, besides launching your learner lab if you're using it, is to obtain your credentials file.
To do this in learner lab, click on AWS details and copy paste the file into ~/.aws/credentials
![image](https://github.com/user-attachments/assets/b2b5ea0c-2a10-44b9-8b8b-42290a23148c)


Next, you will need a key pair. In Windows powershell, use the command ssh-keygen -b 2048 -t rsa -C "yourname" -f filename. Replace yourname with your windows username, and filename with the name of the key file you want. The name can be omitted for a default name.
After generating the key file, link the public key with your AWS EC2 account by searching "key pairs," and then selecting the new .pub file from ~/.ssh/. 

Navigate to the folder where you've extracted the repo, and modify setup_minecraft.sh
The only needed modification is the link, which should be replaced by the link address of the jar file on https://www.minecraft.net/en-us/download/server.
After doing so, navigate to the folder again in your command line. Run 3 commands with terraform

terraform init
terraform plan
terraform apply

These will initialize and setup a server instance on your AWS account that you linked using the key pair and credentials.

After doing so, a long sequence should take place, note that the server will fail to open once to generate the EULA in the process.
After a bit of waiting, the server should be up and running, and display the public IP you can use to connect.
To do so in Minecraft, open the game up and click multiplayer. Then, in direct connect or by adding the server, type in the public IP displayed in the command window followed by ":25565"
The server will autorestart 10 seconds after any issue may cause a crash.

![diagram drawio](https://github.com/user-attachments/assets/1cf42237-b3cf-426c-b169-3f78c54881c3)


References:
Microsoft website for tutorial on SSH keygen
Amazon website for shell script that runs the server once connected with Amazon
Minecraft for server jar file

Sources:
https://learn.microsoft.com/en-us/viva/glint/setup/sftp-ssh-key-gen
https://aws.amazon.com/blogs/gametech/setting-up-a-minecraft-java-server-on-amazon-ec2/
https://www.minecraft.net/en-us/download/server
