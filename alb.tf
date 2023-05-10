resource "aws_security_group" "alb_sg" {
  name   = "ALB SG"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description      = "User to ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "User to ALB"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_route53_record" "www" {

  depends_on = [
    aws_lb.alb
  ]

  zone_id = "Z0535593URHWUZLA596X"
  name    = "devops-kappen.click"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "devops-kappen.click"
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }
}

resource "aws_lb" "alb" {
  internal           = false
  name               = "ALB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]


  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "ALBTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "https_listener" {
  depends_on = [
    aws_lb_target_group.alb_tg,
    aws_vpc.vpc
  ]
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_listener" "http_listener" {
  depends_on = [
    aws_lb_target_group.alb_tg,
    aws_vpc.vpc
  ]
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_security_group" "lc_sg" {
  name   = "LC SG"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description     = "ALB to ASG"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "app_server" {
  image_id        = "ami-0ef75ae6f7891c046"
  instance_type   = "t2.micro"
  name            = "NGINX "
  security_groups = [aws_security_group.lc_sg.id]

  user_data = <<EOF
    #!/bin/bash
    # sudo yum update -y
    # sudo yum install httpd -y
    # sudo systemctl start httpd
    # sudo systemctl enable httpd
    # sudo firewall-cmd --permanent --add-service=http
    # sudo firewall-cmd --reload

    yum update -y
    yum install -y polkit
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    yum install -y git
    cd /var/www/html
    git clone https://github.com/babakDoraniArab/testHtmlTemplate.git
    mv testHtmlTemplate/* ./
    rm -R testHtmlTemplate
    EOF
}

resource "aws_autoscaling_group" "nginx_asg" {
  name                 = "webserver"
  launch_configuration = aws_launch_configuration.app_server.name
  min_size             = 1
  max_size             = 5
  desired_capacity     = 3
  target_group_arns    = [aws_lb_target_group.alb_tg.arn]
  vpc_zone_identifier  = [for subnet in aws_subnet.private_subnets : subnet.id]
}
