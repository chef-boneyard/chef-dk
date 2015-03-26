Data Bags
---------

This directory contains directories of the various data bags you create for your infrastructure. Each subdirectory corresponds to a data bag on the Chef Server, and contains JSON files of the items that go in the bag.

For example, in this directory you'll find an example data bag directory called `example`, which contains an item definition called `example_item.json` 
 
Before uploading this item to the server, we must first create the data bag on the Chef Server.

    knife data bag create example

Then we can upload the items in the data bag's directory to the Chef Server.

    knife data bag from file example example_item.json

For more information on data bags, see the Chef wiki page:
                               
https://docs.getchef.com/essentials_data_bags.html

Encrypted Data Bags
-------------------

Added in Chef 0.10, encrypted data bags allow you to encrypt the contents of your data bags. The content of attributes will no longer be searchable. To use encrypted data bags, first you must have or create a secret key.

    openssl rand -base64 512 > secret_key

You may use this secret_key to add items to a data bag during a create.

    knife data bag create --secret-file secret_key passwords mysql

You may also use it when adding ITEMs from files,

    knife data bag create passwords
    knife data bag from file passwords data_bags/passwords/mysql.json --secret-file secret_key

The JSON for the ITEM must contain a key named "id" with a value equal to "ITEM" and the contents will be encrypted when uploaded. For example,

    {
      "id": "mysql",
      "password": "abc123"
    }

Without the secret_key, the contents are encrypted.

    knife data bag show passwords mysql
    id:        mysql
    password:  2I0XUUve1TXEojEyeGsjhw==

Use the secret_key to view the contents.

    knife data bag show passwords mysql --secret-file secret_key
    id:        mysql
    password:  abc123


For more information on encrypted data bags, see the Chef wiki page:
                               
https://docs.getchef.com/essentials_data_bags.html