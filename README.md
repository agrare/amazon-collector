[![Build Status](https://travis-ci.org/ManageIQ/topological_inventory-amazon.svg?branch=master)](https://travis-ci.org/ManageIQ/topological_inventory-amazon))
[![Maintainability](https://api.codeclimate.com/v1/badges/fd49345c28fa632ba2c6/maintainability)](https://codeclimate.com/github/ManageIQ/topological_inventory-amazon/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/fd49345c28fa632ba2c6/test_coverage)](https://codeclimate.com/github/ManageIQ/topological_inventory-amazon/test_coverage)
[![Security](https://hakiri.io/github/ManageIQ/topological_inventory-amazon/master.svg)](https://hakiri.io/github/ManageIQ/topological_inventory-amazon/master)
## License

This project is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).


AWS user must have these policies attached:

If we are adding AWS Organization's master account, there are these policies needed (these will work for plain AWS account too):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TopologicalInventoryMasterAccount",
            "Effect": "Allow",
            "Action": [
                "organizations:List*",
                "organizations:Describe*",
                "pricing:GetProducts"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "TopologicalInventoryCollection",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeRegions",
                "ec2:DescribeReservedInstances",
                "ec2:DescribeReservedInstancesModifications",
                "ec2:DescribeSnapshots",
                "ec2:DescribeVolumes",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeAddresses",
                "servicecatalog:SearchProductsAsAdmin",
                "servicecatalog:ScanProvisionedProducts",
                "servicecatalog:DescribeProvisioningParameters",
                "servicecatalog:DescribeRecord",
                "servicecatalog:DescribeProduct",
                "servicecatalog:ListLaunchPaths"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

If we want to use Organization's master account and we also want to read data from all sub-accounts, we need to setup
this policy for assume role (so we can connect to sub-accounts from the master account):

(the `*`  in `"arn:aws:iam::*..."` stands for all account ids of all sub-accounts in the Organization, we can
also list here only specific account ids)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeRoleServiceRoleForTopologicalInventory",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:aws:iam::*:role/ServiceRoleForTopologicalInventory"
      ]
    }
  ]
}
```

Then in each sub-account we need to create a role with name `ServiceRoleForTopologicalInventory` with trusted account id
if our master account and this role must have these policies assigned:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TopologicalInventoryCollection",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeRegions",
                "ec2:DescribeReservedInstances",
                "ec2:DescribeReservedInstancesModifications",
                "ec2:DescribeSnapshots",
                "ec2:DescribeVolumes",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeAddresses",
                "servicecatalog:SearchProductsAsAdmin",
                "servicecatalog:ScanProvisionedProducts",
                "servicecatalog:DescribeProvisionedProduct",
                "servicecatalog:DescribeProvisioningParameters",
                "servicecatalog:DescribeRecord",
                "servicecatalog:DescribeProduct",
                "servicecatalog:ListLaunchPaths"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

TBD: provide a script to create/update sub account role in all sub-accounts.
