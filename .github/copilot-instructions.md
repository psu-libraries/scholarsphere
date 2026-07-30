# Copilot Instructions

This repository is a Ruby on Rails application.

## Conventions

- Follow standard Ruby on Rails conventions and idioms.
- Prefer conventional Rails patterns over custom solutions.

## Testing

- The project uses RSpec for testing.
- When generating tests, follow RSpec conventions.
- Use `context` blocks to avoid adding context to `it` blocks

## Development Environment

- The application runs in Docker.
- Use docker-compose when suggesting commands for running the app or tests.
- Prepend "RAILS_ENV=test" to rspec commands when running tests in the development environment.

## Design Principles

- Follow SOLID object-oriented design principles.
- Prefer simple solutions and follow the KISS (Keep It Simple, Stupid) principle.

## Security

- Never read .envrc, .env, or secrets files.