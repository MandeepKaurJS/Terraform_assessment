//Executing terraform and outputting variable for remote state reading
output "vpc_id" {
    value = "${aws_vpc.production_vpc.id}"
}
output "vpc_cidr_block" {
    value = "${aws_vpc.production_vpc.cidr_block}"
}
output "public_subnet1_id" {
    value = "${aws_subnet.subnet1.id}"
}
output "public_subnet2_id" {
    value = "${aws_subnet.subnet2.id}"
}
output "private_subnet1_id" {
    value = "${aws_subnet.private_subnet1.id}"
}
output "private_subnet2_id" {
    value = "${aws_subnet.private_subnet2.id}"
}
