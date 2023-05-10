
# Highly Available Network Archetectur

The terraform project creates highly available network. The project creates 3 public subnets and three private subnets across three availability zones. The public subnets uses internet gateway ( Highly available) to communicate with outer world. The route tables enables the same. The private subnets are communicated through NAT gateway. The NAT gateways are places in each public subnet to make sure it is highly available. The route table of private subnet is designes in such a way to ensure that the NAT gateway connected to the private subnet is in same availability zone ( Otherwise it will incure extra data transfer charges ).

![alt text](https://github.com/sijockappen/network/blob/main/HA%20Network.jpg)


