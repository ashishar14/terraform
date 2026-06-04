variable "bucket_name" {
  type = string
}

variable "ssh_key_name" {
  type        = string
  default     = "mykeyppk"
  description = "Existing AWS EC2 key pair name for SSH access. Corresponds to your private key file name without extension."
}

variable "vpc_id" {
  type        = string
  default     = "vpc-023386d779f622a50"
  description = "Existing VPC ID where EC2 instances should be launched."
}

variable "security_group_id" {
  type        = string
  default     = "sg-06f2ffd54d568bf12"
  description = "Existing security group ID to attach to the EC2 instances."
}

variable "jenkins_master_url" {
  type        = string
  default     = ""
  description = "Jenkins master URL for the agent to connect to, e.g. https://jenkins.example.com"
}

variable "jenkins_agent_name" {
  type        = string
  default     = ""
  description = "Jenkins node name for the agent configuration."
}

variable "jenkins_agent_secret" {
  type        = string
  default     = ""
  description = "Jenkins JNLP agent secret for the agent node."
  sensitive   = true
}