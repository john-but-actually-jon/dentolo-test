terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 3.5.0"
        region = "eu-west-1"
      }
    }
}


#* This is the bucket that would be used for version control
#* of all the relevant DAGs. Can separate prod and dev DAGs 
#* with config files
data "aws_s3_bucket" "airflow_mwaa" {
  bucket = "s3://mwaa-airflow-source" # The name is up for debate
}

resource "aws_mwaa_environment" "data_prod" {
  airflow_configuration_options ={
    "core.default_task_retries" = 5
    "core.parallelism" = 20 # Eyeballing it
    "celery.worker_autoscale" = 16,12
  }

  dag_s3_path = "dags/"
  execution_role_arn = aws_iam_role.mwaa_role.arn
  name = "mwaa-airflow"

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "DEBUG"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = true
      log_level = "ERROR"
    }

    worker_logs {
      enabled   = true
      log_level = "ERROR"
    }
  }

  environment_class = "mw1.medium"

  network_configuration {
    security_group_ids = [aws_security_group.mwaa_prod.id]
    subnet_ids = aws_subnet.private[*].id
  }

  source_bucket_arn = aws_s3_bucket.airflow_mwaa.arn

  tags = {
    Name = "MWAA Airflow"
    Environment = "production"
  }
}

