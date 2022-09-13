terraform {
  required_version = ">= 0.12.0"
}


# provider "aws" {
#   region = "eu-central-1"
# }


# RESOURCES
# Objects managed by Terraform such as VPCs, S3 buckets, IAM users, etc.
# Declaring a Resource tells Terraform that it should CREATE
# and manage the Resource described. If the resource already exists
# it must be imported into Terraform's state.
resource "aws_s3_bucket" "bucket1" {
  bucket = "${data.aws_caller_identity.current.account_id}-imanbucket"
}

# Data Sources
# Objects NOT managed by Terraform . That are not resources that you can create
data "aws_caller_identity" "current" {
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Outputs
# Outputs are printed by the CLI after `apply`.
# this can reveal calculated values or other information
# Also used in more advanced use cases :  modules, remote_state
# Outputs can be retrieved at any time bu running `terraform output`
output "bucket_info" {
  value = aws_s3_bucket.bucket1
}

output "aws_caller_inf" {
  value = data.aws_caller_identity.current
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available
}


output "bucketname" {
  value = data.aws_caller_identity.current.account_id
}


# Dependency
# Resources can depend on one another. Terraform will ensure that all dependencies are met before creating the resource.
# Dependencies can be implicit or explicit.
resource "aws_s3_bucket" "bucket2" {
  bucket = "${data.aws_caller_identity.current.account_id}-bucket2"
  tags = {
    # Implicit dependency
    dependency = aws_s3_bucket.bucket1.arn
  }
}
  
resource "aws_s3_bucket" "bucket3" {
  bucket = "${data.aws_caller_identity.current.account_id}-bucket3"
  # Explicit dependency
  depends_on = [
    aws_s3_bucket.bucket2
  ]
}

# Variables
# Can be specified on the command line with "-var bucket_name=my-bucket"
# or in files: terraform.tfvars or *.auto.tfvars
# or in environment variables: TF_VAR_bucket_name
variable "bucket_name" {
  # `type` is an optional data type specification.
  type = string
  # `default` is the optional default value. If `default` is not specified,
  # then a value must be supplied.
  default = "my-bucket1231293342234"
}

resource "aws_s3_bucket" "bucket4" {
  bucket = var.bucket_name
}

#Local Values
# Local values allow you to assign a name to an expression. Locals can make your code more readable.
# locals allows your to store the resualt of terraform expression in a variable.
# instead of writing the expression so many times, you can store it in a local and use it later.
# expression can be output of a terraform function or ...
#A local value assigns a name to an expression, so you can use it multiple times within a module without repeating it.
#If you're familiar with traditional programming languages, it can be useful to compare Terraform modules to function definitions:
#    Input variables are like function arguments.
#    Output values are like function return values.
#    Local values are like a function's temporary local variables.

locals {
  aws_account = "${data.aws_caller_identity.current.account_id}-${lower(data.aws_caller_identity.current.user_id)}"
}

resource "aws_s3_bucket" "bucket5" {
  bucket = "${local.aws_account}-bucket5"
}

## Count

# All resources have a `count` parameter. the default is 1.
# By default, a resource block configures one real infrastructure object. 
#(Similarly, a module block includes a child module's contents into the configuration one time.) However, 
# sometimes you want to manage several similar objects (like a fixed pool of compute instances) without 
# writing a separate block for each one. Terraform has two ways to do this: count and for_each.

# The count meta-argument accepts numeric expressions. However, unlike most arguments, 
# the count value must be known before Terraform performs any remote resource actions. 
# This means count can't refer to any resource attributes that aren't known until after a 
# configuration is applied (such as a unique ID generated by the remote API when an object is created).

# count.index — The distinct index number (starting with 0) corresponding to this instance.
# If `count` is set then a "count.index" value is available, this value contains the current iteration number.

resource "aws_s3_bucket" "bucketX" {
  count = 2
  #count = 0
  # you can use "count = 0" when you want to delete your temproary resources instead of comenting this resource block.
  bucket = "${local.aws_account}-bucket${count.index+7}"
}


## for_each

# Note: A given resource or module block cannot use both count and for_each.

# The for_each meta-argument accepts a map or a set of strings, and creates an instance 
# for each item in that map or set. Each instance has a distinct infrastructure object associated with it, 
# and each is separately created, updated, or destroyed when the configuration is applied.

# If "for_each" is set then a resource is created for each item in the set.
# If special "each" object is available, the each object has `key` and `value` attributes that can be referenced.

locals {
  buckets = {
    bucket101 = "mybucket101"
    bucket102 = "mybucket102"
  }
}

resource "aws_s3_bucket" "bucketE" {
  for_each = local.buckets
  bucket = "${local.aws_account}-${each.value}"
}

# # If we have list instead of set
# locals {
#   buckets = [
#     "mybucket101",
#     "mybucket102"
#   ]
# }

# # convert list to set by using toset() function and because we do not have "value" in list we use "each.key"
# resource "aws_s3_bucket" "bucketE" {
#   for_each = toset(local.buckets)
#   bucket = "${local.aws_account}-${each.key}"
# }



## Data types
# terraform supports the following data types:
locals {
  a_string = "This is a string"
  a_number = 1.12456
  a_bool = true
  a_list = ["a", "b", "c"]
  a_map = {
    key = "value"
    a = "a"
    b = "b"
  }

  # Complex data types
  person = {
    name = "John Doe",
    phone_number = {
      home = "415-444-1212"
      mobile = "415-555-1313"
    },
    active = false,
    age = 42,
    address = {
      street = "123 Main St"
      city = "Anytown"
      state = "CA"
      zip = "12345"
    }
  }
}

output "home_phone" {
  value = local.person.phone_number.home
}



## Operators
# Terraform supports arithmetic and logical operations in expression too
locals {
  // Arithmetic
  three = 1 + 2 // addition
  two   = 3 - 1 // subtraction
  one   = 2 / 2 // division
  zero  = 1 * 0 // multiplication

  // Logical
  t = true || false // OR : true if either value is true
  f = true && false // AND : true if both values are true

  // Comparison
  gt  = 2 > 1 // true if right value is greater than left value
  gte = 2 >= 1 // true if right value is greater than or equal to left value
  lt  = 1 < 2 // true if right value is less than left value
  lte = 1 <= 2 // true if right value is less than or equal to left value
  eq  = 1 == 1 // true if left and right values are equal
  neq = 1 != 2 // true if left and right values are not equal 
}

output "arithmetic" {
  value = "${local.zero} ${local.one} ${local.two} ${local.three}"
}

output "logical" {
  value = "${local.t} ${local.f}"
}

output "comparison" {
  value = "${local.gt} ${local.gte} ${local.lt} ${local.lte} ${local.eq} ${local.neq}"
}


## Conditionals
variable "bucket_count" {
  type = number
}

locals {
  minimum_number_of_buckets = 5
  number_of_buckets = var.bucket_count > 0 ? var.bucket_count : local.minimum_number_of_buckets
  # it is if statement . the section to the left of the "?" is the if condition
  # left side of ":" will be `if` true acction and right side of ":" will be `if` false action
  # so if your bucket_count is greater than 0 then mumber_of_buckets will be bucket_count
  # else it will be minimum_number_of_buckets
}

resource "aws_s3_bucket" "buckets" {
  count = local.number_of_buckets
  bucket = "${local.aws_account}-bucket${count.index+20}"
}


## Functions
# Terraform has 100+ built-in functions (but no ability to define custom functions )
# https://www.terraform.io/language/functions
# The syntax for functions is: <function_name>(<arg1>, <arg2>, ...).
locals {
  //Date and Time
  ts = timestamp() // returns the current time in UTC
  current_month = formatdate("MMMM", local.ts) // returns the current month in text format
  tomorrow = formatdate("DD", timeadd(local.ts, "24h")) // returns the day of the next day in text format")
  my_date_format = formatdate("YYYY-MM-DD", local.ts)
}

output "date_time" {
  value = "${local.current_month} ${local.tomorrow} ${local.my_date_format}"
}

locals {
  //Numberic
  number_of_buckets_2 = min(local.minimum_number_of_buckets, var.bucket_count)
}

locals {
  //String
  lcase = "${lower("A mixed case String")}"
  ucase = "${upper("A lower case string")}"
  trimmed = "${trimspace("   A string with leading and trailing spaces   ")}"
  formatted = "${format("A string with a number %d", 1)}"
  formatted_list = "${formatlist("Hello, %s", ["Mammad", "Iman", "John"])}"
}

output "string_functions" {
  value = "${local.formatted_list}"
}

output "string_function2" {
  value = "${local.lcase} ${local.ucase} ${local.trimmed} ${local.formatted}"
}

## Iteration
locals {
  l = ["one", "two", "three"]
  upper_list = [for i in local.l : upper(i)]
  upper_map = {for item in local.l : item => upper(item) }
}

output "iterations" {
  value = local.upper_list
}

## Filtering
locals {
  n = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  evens = [for i in local.n : i if i % 2 == 0]
}

output "filtered" {
  value = local.evens
}

## Directives and heredocs
# HCL supports more complex string templating that can be used to generate full declarative paragraphs too.
output "heredoc" {
  # `-` tells terraform to ignore indentation 
  value = <<-EOT
    This is a `heredoc` . It's a string literal
    that can span multiple lines.
  EOT
}

output "directive" {
  # `-` tells terraform to ignore indentation 
  value = <<-EOT
    This is a `heredoc`  with directives.
    %{ if local.person.name == "" }
    Sorry, we don't have a name for you.
    %{ else }
    Hi ${local.person.name}
    %{ endif }
  EOT
}

output "iterated" {
  value = <<-EOT
  Directives can also iterate...
  %{ for number in local.evens}
  ${number} is even.
  %{ endfor }
EOT
}