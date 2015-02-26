## 0.5.x

### 0.5.0

* **[_potentially_ breaking change]** MongoDB driver updated to 2.x. If you use the `db` object in your migrations
check this [article](http://mongodb.github.io/node-mongodb-native/2.0/tutorials/changes-from-1.0/)
for the list of differences.

## 0.4.x

### 0.4.1

* hotfix release

### 0.4.0

* switched to native MongoClient.connect, removed dependency on mongo-pool2

## 0.3.x

### 0.3.1

* Added Migrator#dispose to close the MongoDB connections

### 0.3.0

* Updated mongo-pool2 to 0.1.0 which has MongoDB driver 1.4.x

## 0.2.x

### 0.2.0

* **[breaking change]** Simplify the expected config file structure — all keys are expected on the top level

## 0.1.x

### 0.1.2

* Minor README update

### 0.1.1

* Minor README update
* Technical release for fixing npm publish issue

### 0.1.0

* Full README
* More tests

## 0.0.x

### 0.0.9
Automatically pick mm-config.{js,json,coffee}

### 0.0.8
Fix for the case when migrations directory does not exist

### 0.0.7
Report exact skip reason

### 0.0.6
Binary bugfix

### 0.0.5
Binary bugfix

### 0.0.4
Binary file for creating and running migrations

### 0.0.3
Allow creating migration stubs

### 0.0.2
Allow running migrations from directory

### 0.0.1
Initial release, has tests, allows migration and rollback, only programmatic API
