# Commands Run

1. Create a new Rails project
   ```bash
   rails new <PROJECT_NAME>
   ```
2. Install `bundler`
   ```bash
   gem install bundler:2.6.3
   ```
3. Generate `User` files
   ```bash
   rails generate model User name:string
   ```
4. Generate `SleepRecord` files
   ```bash
   rails generate model SleepRecord user:references start_time:timestamp end_time:timestamp duration:integer
   ```
5. Add password digest to User model
   ```bash
   rails generate migration AddPasswordDigestToUsers password_digest:string
   ```
6. Generate JWT authentication files
   ```bash
   rails generate controller Api::V1::Authentication login
   ```