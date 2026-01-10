# Has One Association

## Description
Defines a one-to-one relationship where the current model owns exactly one record of another model.

## Key Points
- Use `hasOne()` in model's `config()` method
- Use singular form for association name
- Foreign key exists in related model's table
- Less common than hasMany but useful for table splits
- Generates convenience methods for accessing related record

## Code Sample
```cfm
// User model - a user has one profile
component extends="Model" {
    function config() {
        hasOne("profile");

        // Custom foreign key
        hasOne("account", foreignKey="userId");

        // With conditions
        hasOne("activeProfile",
               modelName="profile",
               where="active = 1");
    }
}

// Profile model - a profile belongs to a user
component extends="Model" {
    function config() {
        belongsTo("user");
    }
}

// Usage in controllers/views
user = model("user").findByKey(1);
profile = user.profile();                // Get associated profile
newProfile = user.newProfile();          // Create associated profile
user.setProfile(profile);                // Set association
hasProfile = user.hasProfile();          // Check if has profile
```

## Usage
1. Add `hasOne("associationName")` in model's `config()` method
2. Use singular association name (profile, account, setting)
3. Ensure foreign key exists in related model's table
4. Access via generated method: `object.associationName()`
5. Create new associated object: `object.newAssociationName()`

## Related
- [Has Many Association](./has-many.md)
- [Belongs To Association](./belongs-to.md)
- [ORM Mapping](../../core-concepts/orm/mapping-basics.md)

## Important Notes
- Use singular form for hasOne associations
- Foreign key must exist in related model's table
- Typically paired with belongsTo in related model
- Common for table splits and optional data
- Less frequently used than hasMany associations