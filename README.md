
# Highly Available Network Architecture

The terraform project creates a highly available network. The project creates 3 public subnets and three private subnets across three availability zones. The public subnets use an internet gateway ( Highly available) to communicate with the outer world. The route tables enable the same. The private subnets are communicated through the NAT gateway. The NAT gateways are placed in each public subnet to make sure it is highly available. The route table of the private subnet is designed in such a way as to ensure that the NAT gateway connected to the private subnet is in the same availability zone ( Otherwise it will incur extra data transfer charges ).

![alt text](https://github.com/sijockappen/network/blob/main/HA%20Network.jpg)


