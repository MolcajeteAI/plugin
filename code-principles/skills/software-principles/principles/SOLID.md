# SOLID - Object-Oriented Design Principles

## Overview

SOLID is an acronym for five design principles intended to make object-oriented designs more understandable, flexible, and maintainable. These principles were introduced by Robert C. Martin (Uncle Bob).

**S** - Single Responsibility Principle (SRP)
**O** - Open/Closed Principle (OCP)
**L** - Liskov Substitution Principle (LSP)
**I** - Interface Segregation Principle (ISP)
**D** - Dependency Inversion Principle (DIP)

---

## S - Single Responsibility Principle (SRP)

### Definition
**A class should have only one reason to change.**

Each class should have one job or responsibility. If a class has more than one responsibility, those responsibilities become coupled, and changes to one may affect the other.

### Examples

**Bad - Multiple Responsibilities:**
```javascript
class User {
  constructor(name, email) {
    this.name = name;
    this.email = email;
  }

  // Responsibility 1: User data management
  getName() {
    return this.name;
  }

  // Responsibility 2: Database operations
  save() {
    database.save('users', this);
  }

  // Responsibility 3: Email operations
  sendEmail(message) {
    emailService.send(this.email, message);
  }

  // Responsibility 4: Validation
  validate() {
    if (!this.email.includes('@')) throw new Error('Invalid email');
  }
}
```

**Good - Single Responsibility:**
```javascript
// Responsibility: User data management
class User {
  constructor(name, email) {
    this.name = name;
    this.email = email;
  }

  getName() {
    return this.name;
  }

  getEmail() {
    return this.email;
  }
}

// Responsibility: Database operations
class UserRepository {
  save(user) {
    database.save('users', user);
  }

  findById(id) {
    return database.findById('users', id);
  }
}

// Responsibility: Email operations
class UserNotifier {
  sendEmail(user, message) {
    emailService.send(user.getEmail(), message);
  }
}

// Responsibility: Validation
class UserValidator {
  validate(user) {
    if (!user.getEmail().includes('@')) {
      throw new Error('Invalid email');
    }
  }
}
```

### Common Violations
- God classes that do everything
- Classes that handle both business logic and infrastructure
- Mixing presentation logic with business logic
- Combining data validation with data transformation

---

## O - Open/Closed Principle (OCP)

### Definition
**Software entities should be open for extension but closed for modification.**

You should be able to add new functionality without changing existing code. Use abstraction and polymorphism to achieve this.

### Examples

**Bad - Modification Required:**
```javascript
class PaymentProcessor {
  processPayment(payment) {
    if (payment.type === 'credit_card') {
      // Process credit card
      this.chargeCreditCard(payment);
    } else if (payment.type === 'paypal') {
      // Process PayPal
      this.chargePayPal(payment);
    } else if (payment.type === 'bitcoin') {
      // Process Bitcoin
      this.chargeBitcoin(payment);
    }
    // Adding new payment type requires modifying this class
  }
}
```

**Good - Extension Without Modification:**
```javascript
// Abstract interface
class PaymentMethod {
  process(amount) {
    throw new Error('Must implement process()');
  }
}

// Concrete implementations
class CreditCardPayment extends PaymentMethod {
  process(amount) {
    // Credit card processing logic
    console.log(`Processing $${amount} via credit card`);
  }
}

class PayPalPayment extends PaymentMethod {
  process(amount) {
    // PayPal processing logic
    console.log(`Processing $${amount} via PayPal`);
  }
}

class BitcoinPayment extends PaymentMethod {
  process(amount) {
    // Bitcoin processing logic
    console.log(`Processing $${amount} via Bitcoin`);
  }
}

// Processor works with any payment method
class PaymentProcessor {
  processPayment(paymentMethod, amount) {
    paymentMethod.process(amount);
  }
}

// Adding new payment type doesn't require changing PaymentProcessor
class ApplePayPayment extends PaymentMethod {
  process(amount) {
    console.log(`Processing $${amount} via Apple Pay`);
  }
}
```

### Common Violations
- Switch/case statements that grow with new features
- If/else chains checking object types
- Hard-coded dependencies on concrete classes
- Classes that need modification for every new requirement

---

## L - Liskov Substitution Principle (LSP)

### Definition
**Objects of a superclass should be replaceable with objects of a subclass without breaking the application.**

Subtypes must be substitutable for their base types. The behavior of subclasses should not violate expectations set by the base class.

### Examples

**Bad - Violates LSP:**
```javascript
class Rectangle {
  constructor(width, height) {
    this.width = width;
    this.height = height;
  }

  setWidth(width) {
    this.width = width;
  }

  setHeight(height) {
    this.height = height;
  }

  getArea() {
    return this.width * this.height;
  }
}

class Square extends Rectangle {
  setWidth(width) {
    this.width = width;
    this.height = width; // Violates expectations
  }

  setHeight(height) {
    this.width = height; // Violates expectations
    this.height = height;
  }
}

// This breaks with Square
function testRectangle(rectangle) {
  rectangle.setWidth(5);
  rectangle.setHeight(4);
  console.assert(rectangle.getArea() === 20); // Fails for Square!
}
```

**Good - Respects LSP:**
```javascript
class Shape {
  getArea() {
    throw new Error('Must implement getArea()');
  }
}

class Rectangle extends Shape {
  constructor(width, height) {
    super();
    this.width = width;
    this.height = height;
  }

  setWidth(width) {
    this.width = width;
  }

  setHeight(height) {
    this.height = height;
  }

  getArea() {
    return this.width * this.height;
  }
}

class Square extends Shape {
  constructor(size) {
    super();
    this.size = size;
  }

  setSize(size) {
    this.size = size;
  }

  getArea() {
    return this.size * this.size;
  }
}

// Works with any Shape
function printArea(shape) {
  console.log(`Area: ${shape.getArea()}`);
}
```

### Common Violations
- Subclasses that throw exceptions for base class methods
- Subclasses that return different types than base class
- Subclasses that add preconditions not in base class
- Subclasses that weaken postconditions of base class

---

## I - Interface Segregation Principle (ISP)

### Definition
**Clients should not be forced to depend on interfaces they don't use.**

Many specific interfaces are better than one general-purpose interface. Don't force classes to implement methods they don't need.

### Examples

**Bad - Fat Interface:**
```javascript
class Worker {
  work() {
    throw new Error('Must implement work()');
  }

  eat() {
    throw new Error('Must implement eat()');
  }

  sleep() {
    throw new Error('Must implement sleep()');
  }
}

class Human extends Worker {
  work() {
    console.log('Human working');
  }

  eat() {
    console.log('Human eating');
  }

  sleep() {
    console.log('Human sleeping');
  }
}

class Robot extends Worker {
  work() {
    console.log('Robot working');
  }

  eat() {
    throw new Error('Robots don\'t eat'); // Forced to implement
  }

  sleep() {
    throw new Error('Robots don\'t sleep'); // Forced to implement
  }
}
```

**Good - Segregated Interfaces:**
```javascript
class Workable {
  work() {
    throw new Error('Must implement work()');
  }
}

class Eatable {
  eat() {
    throw new Error('Must implement eat()');
  }
}

class Sleepable {
  sleep() {
    throw new Error('Must implement sleep()');
  }
}

class Human extends Workable {
  constructor() {
    super();
    this.eatable = new EatableBehavior();
    this.sleepable = new SleepableBehavior();
  }

  work() {
    console.log('Human working');
  }
}

class Robot extends Workable {
  work() {
    console.log('Robot working');
  }
  // No need to implement eat() or sleep()
}
```

### Common Violations
- Interfaces with many methods
- Classes implementing interfaces with empty methods
- Classes throwing "not implemented" exceptions
- Forcing clients to depend on methods they don't use

---

## D - Dependency Inversion Principle (DIP)

### Definition
**High-level modules should not depend on low-level modules. Both should depend on abstractions.**

Also: **Abstractions should not depend on details. Details should depend on abstractions.**

Depend on interfaces or abstract classes rather than concrete classes.

### Examples

**Bad - Direct Dependencies:**
```javascript
class MySQLDatabase {
  save(data) {
    console.log('Saving to MySQL:', data);
  }
}

class UserService {
  constructor() {
    this.database = new MySQLDatabase(); // Direct dependency
  }

  createUser(userData) {
    // Business logic
    this.database.save(userData);
  }
}

// Hard to switch databases or test
```

**Good - Dependency Injection:**
```javascript
// Abstraction
class Database {
  save(data) {
    throw new Error('Must implement save()');
  }
}

// Low-level modules
class MySQLDatabase extends Database {
  save(data) {
    console.log('Saving to MySQL:', data);
  }
}

class MongoDatabase extends Database {
  save(data) {
    console.log('Saving to MongoDB:', data);
  }
}

// High-level module depends on abstraction
class UserService {
  constructor(database) {
    this.database = database; // Injected dependency
  }

  createUser(userData) {
    // Business logic
    this.database.save(userData);
  }
}

// Easy to switch or test
const mysqlService = new UserService(new MySQLDatabase());
const mongoService = new UserService(new MongoDatabase());
const testService = new UserService(new MockDatabase());
```

### Common Violations
- Direct instantiation of dependencies inside classes
- Hard-coded dependencies on concrete classes
- Tight coupling between layers
- Inability to test without real dependencies

---

## Applying SOLID Principles

### Start with SRP
- Identify responsibilities in existing classes
- Extract classes with single responsibilities
- Name classes based on their single responsibility

### Add OCP
- Identify areas that change frequently
- Create abstractions for variation points
- Use polymorphism instead of conditionals

### Ensure LSP
- Test substitutability of subclasses
- Verify behavior consistency
- Avoid strengthening preconditions in subclasses

### Apply ISP
- Split large interfaces
- Create role-based interfaces
- Let clients depend on minimal interfaces

### Implement DIP
- Identify dependencies between layers
- Create abstractions for dependencies
- Use dependency injection

## Benefits

1. **Maintainability** - Easier to change and update
2. **Testability** - Components can be tested in isolation
3. **Flexibility** - Easy to add new features
4. **Reusability** - Components can be reused in different contexts
5. **Readability** - Clear responsibilities and relationships

## When to Apply

- **Always**: SRP and DIP for maintainable code
- **Often**: OCP for areas that change frequently
- **When needed**: LSP when using inheritance
- **Judiciously**: ISP when interfaces grow large

## Common Mistakes

1. **Over-engineering** - Applying all principles everywhere
2. **Premature abstraction** - Creating interfaces too early
3. **Analysis paralysis** - Spending too much time on design
4. **Ignoring pragmatism** - Following principles over shipping

## Summary

SOLID principles guide you toward better object-oriented design. They're guidelines, not rules. Apply them with judgment based on your specific context, team, and project needs. Start with SRP and DIP, add others as complexity grows.
