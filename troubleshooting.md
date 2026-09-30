1. NAT Service Startup Failure
Problem Witnessed

During deployment of the EC2-based NAT Instance, the custom systemd service failed to start:

Failed to start nat.service
Job for nat.service failed because the control process exited with error code.

The NAT Instance itself was successfully created and running, with:

Source/Destination Check: Disabled

However, the NAT configuration using IP forwarding and iptables MASQUERADE was not successfully initialized.

How We Are Solving It

We are troubleshooting the NAT Instance layer by layer:

Verifying the EC2 instance configuration
Checking VPC route tables
Enabling IP forwarding
Installing/configuring iptables
Checking the nat.service systemd configuration
Inspecting cloud-init and EC2 console output
Validating private-subnet connectivity through the NAT Instance

The issue is currently under investigation, and end-to-end private subnet connectivity will be validated after the NAT service is successfully initialized.