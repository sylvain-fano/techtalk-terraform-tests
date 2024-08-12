variables {
  region = "eu-central-1"
}

provider "aws" {
  region  = var.region
  profile = "Cloud_Platform_Engineering_Sandbox/Developer"

  default_tags {
    tags = merge(
      {
        "Environment" = "SANDBOX"
        "Tool"        = "TECH_TALK"
        "24/7"        = "false"
        "Source"      = "https://github.com/sylvain-fano/techtalk-terraform-tests"
      }
    )
  }
}

#########################
# UNIT TESTS
#########################
run "input_validation" {
  command = plan
  # Invalid values
  variables {
    bucket_name = "long-name-which-is-longer-than-maximum-allowed-length"
    region      = "us-east-1"
  }
  expect_failures = [
    var.bucket_name,
    var.region,
  ]
}


#########################
# INTEGRATION TESTS
#########################

# HELPER MODULE : Call the setup module to create a random bucket prefix
run "setup_tests" {
  command = apply
  module {
    source = "./tests/setup"
  }
}

# Apply run block to create the bucket
run "create_bucket" {
  command = apply

  variables {
    bucket_name = "${run.setup_tests.bucket_prefix}-aws-s3-website-test"
  }

  # Check that the bucket name is correct
  assert {
    condition     = aws_s3_bucket.s3_bucket.bucket == "${run.setup_tests.bucket_prefix}-aws-s3-website-test"
    error_message = "Invalid bucket name"
  }

  # Check index.html hash matches
  assert {
    condition     = aws_s3_object.index.etag == filemd5("./www/index.html")
    error_message = "Invalid eTag for index.html"
  }

  # Check error.html hash matches
  assert {
    condition     = aws_s3_object.error.etag == filemd5("./www/error.html")
    error_message = "Invalid eTag for error.html"
  }
}

run "website_is_running" {
  command = plan

  module {
    source = "./tests/final"
  }

  variables {
    endpoint = run.create_bucket.website_endpoint
  }

  assert {
    condition     = data.http.index.status_code == 200
    error_message = "Website responded with HTTP status ${data.http.index.status_code}"
  }
}
