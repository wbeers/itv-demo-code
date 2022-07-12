resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.prefix}iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "iam_for_lambda_policy" {
  name = "iam_for_lambda_policy"
  role = aws_iam_role.iam_for_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Action": [
                "codepipeline:PutJobSuccessResult",
                "codepipeline:PutJobFailureResult"
            ],
            "Effect": "Allow",
            "Resource": "*"
    },
	{
        "Effect": "Allow",
        "Action": [
            "cloudfront:CreateInvalidation"
        ],
        "Resource": [
            "*"
        ]
    }
  ]
  })
}

data "archive_file" "lambda_zip_file" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content  = file("lambda_function.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "s3_pipeline_lambda" {
  filename                       = "${data.archive_file.lambda_zip_file.output_path}"
  source_code_hash               = "${data.archive_file.lambda_zip_file.output_base64sha256}"
  function_name                  = "${var.prefix}s3_pipeline_lambda"
  role                           = aws_iam_role.iam_for_lambda.arn
  handler                        = "lambda_function.lambda_handler"
  runtime = "python3.9"

  environment {
    variables = {
      distribution  = aws_cloudfront_distribution.s3-cloudfront.id
    }
  }
}


resource "aws_codepipeline" "s3-pipeline" {
  artifact_store {
    location = aws_s3_bucket.s3-site.bucket
    type     = "S3"
  }

  name     = "${var.prefix}pipeline"
  role_arn = "arn:aws:iam::781196510485:role/service-role/AWSCodePipelineServiceRole-us-east-1-s3-static-pipeline"

  stage {
    action {
      category = "Source"

      configuration = {
        BranchName           = "main"
        ConnectionArn        = "arn:aws:codestar-connections:us-east-1:781196510485:connection/3c239c9d-392d-4257-9b23-df8fd6df2ea1"
        FullRepositoryId     = "wbeers/s3-static-site"
        OutputArtifactFormat = "CODE_ZIP"
      }

      name             = "Source"
      namespace        = "SourceVariables"
      output_artifacts = ["SourceArtifact"]
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      region           = "us-east-1"
      run_order        = "1"
      version          = "1"
    }

    name = "Source"
  }
  
    stage {
    action {
      category = "Deploy"

      configuration = {
        BucketName = aws_s3_bucket.s3-site.bucket
        Extract    = "true"
      }

      input_artifacts = ["SourceArtifact"]
      name            = "Deploy"
      namespace       = "DeployVariables"
      owner           = "AWS"
      provider        = "S3"
      region          = "us-east-1"
      run_order       = "1"
      version         = "1"
    }

    name = "Deploy"
  }

stage {
      action {
      input_artifacts = ["SourceArtifact"]
      name            = "Invalidate"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      region          = "us-east-1"
      run_order       = "1"
      version         = "1"
      configuration = {
        FunctionName    = aws_lambda_function.s3_pipeline_lambda.function_name
      }
      

    }
   name = "Invalidate"
  }

}
