# Good Night Application

A Rails API application that helps users track their sleep patterns and follow other users' sleep records.

## Overview

This application provides RESTful APIs that allow users to:
- Record their bedtime (Clock In)
- Track when they wake up (Clock Out)
- Follow/Unfollow other users
- View sleep records of users they follow

## System Requirements

- Ruby 3.3.6
- Rails 7.2.1
- SQLite3 (for local dev)

## Setup

1. Clone the repository

2. Install dependencies:
```bash
bundle install
```

3. Setup database:
```bash
rails db:create
rails db:migrate
```

4. Start the server:
```bash
rails server
```

## API Endpoints

### Authentication

```
POST /api/v1/authentication/login
```
Generates JWT token for user authentication

### Sleep Records

```
POST /api/v1/sleep_records/clock_in
```
Records when user goes to bed

```
POST /api/v1/sleep_records/clock_out
```
Records when user wakes up

```
GET /api/v1/sleep_records
```
Returns all sleep records for the authenticated user

### Following

```
POST /api/v1/follows
```
Follow a user

```
DELETE /api/v1/follows/:id
```
Unfollow a user

```
GET /api/v1/sleep_records/following
```
Get sleep records of all followed users from the previous week, sorted by sleep duration

## Testing

The application includes unit tests, integration tests, and system tests. To run the test suite:

```bash
rails test
```
