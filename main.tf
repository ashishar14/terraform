data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_subnet_ids" "vpc_subnets" {
  vpc_id = var.vpc_id
}

resource "aws_instance" "my_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet_ids.vpc_subnets.ids[0]
  vpc_security_group_ids      = [var.security_group_id]

  key_name = var.ssh_key_name != "" ? var.ssh_key_name : null

  tags = {
    Name = "my-ec2"
  }
}

resource "aws_instance" "jenkins_agent" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet_ids.vpc_subnets.ids[0]
  vpc_security_group_ids      = [var.security_group_id]

  key_name = var.ssh_key_name != "" ? var.ssh_key_name : null

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y openjdk-17-jdk wget
              useradd -m -s /bin/bash jenkins || true
              mkdir -p /home/jenkins/agent
              chown -R jenkins:jenkins /home/jenkins
              if [ -n "${var.jenkins_master_url}" ] && [ -n "${var.jenkins_agent_secret}" ] && [ -n "${var.jenkins_agent_name}" ]; then
                wget -O /home/jenkins/agent/agent.jar "${var.jenkins_master_url}/jnlpJars/agent.jar"
                chown jenkins:jenkins /home/jenkins/agent/agent.jar
                cat > /etc/systemd/system/jenkins-agent.service <<'SERVICE'
[Unit]
Description=Jenkins JNLP Agent
After=network.target

[Service]
User=jenkins
WorkingDirectory=/home/jenkins/agent
ExecStart=/usr/bin/java -jar /home/jenkins/agent/agent.jar -jnlpUrl ${var.jenkins_master_url}/computer/${var.jenkins_agent_name}/jenkins-agent.jnlp -secret ${var.jenkins_agent_secret} -workDir /home/jenkins/agent
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE
                systemctl daemon-reload
                systemctl enable jenkins-agent
                systemctl start jenkins-agent
              fi
              EOF

  tags = {
    Name = "jenkins-agent"
  }
}

output "my_ec2_public_ip" {
  value = aws_instance.my_ec2.public_ip
}

output "jenkins_agent_public_ip" {
  value = aws_instance.jenkins_agent.public_ip
}

output "jenkins_agent_ssh_command" {
  value = var.ssh_key_name != "" ? "ssh -i ~/.ssh/${var.ssh_key_name}.pem ubuntu@${aws_instance.jenkins_agent.public_ip}" : "ssh ubuntu@${aws_instance.jenkins_agent.public_ip}"
}