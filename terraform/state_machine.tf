resource "aws_sfn_state_machine" "check_in" {
  name     = "check-in"
  role_arn = "${aws_iam_role.state_machine.arn}"

  definition = <<EOF
{
  "Comment": "Checks in a Southwest reservation",
  "StartAt": "ScheduleCheckIn",
  "States": {
    "ScheduleCheckIn": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.sw_schedule_check_in.arn}",
      "Next": "WaitUntilCheckIn"
    },
    "WaitUntilCheckIn": {
      "Type": "Wait",
      "TimestampPath": "$.check_in_times.next",
      "Next": "CheckIn"
    },
    "CheckIn": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.sw_check_in.arn}",
      "ResultPath": "$.is_last_check_in",
      "Next": "IsLastCheckIn",
      "Retry": [
        {
          "ErrorEquals": ["SouthwestAPIError"],
          "IntervalSeconds": 2,
          "MaxAttempts": 10
        }
      ]
    },
    "IsLastCheckIn": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.is_last_check_in",
          "BooleanEquals": false,
          "Next": "ScheduleCheckIn"
        }
      ],
      "Default": "Done"
    },
    "Done": {
      "Type": "Pass",
      "End": true
    }
  }
}
EOF
}
