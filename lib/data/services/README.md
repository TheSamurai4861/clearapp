# Data Services

This layer interacts directly with external resources, OS components, the file system, databases, or API endpoints.

## Contents
* **File Scanner Service**: Performs recursive directory traversal, hash computation (MD5/SHA256), and filters duplicates.
* **Storage/Database Service**: Interacts with local databases (Hive, Isar, SQFlite, or shared preferences).
* **Models**: Data transfer objects or serialization models (e.g., `DuplicateFileModel` that extends `DuplicateFile` but adds `fromJson`/`toJson` or database annotations).

## Guidelines
* Handle heavy operations (like hashing thousands of files) asynchronously.
* Utilize Dart isolates or compute functions to offload expensive file scanning from the UI thread.
