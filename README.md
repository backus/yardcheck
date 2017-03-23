# Yardcheck

Check whether your YARD types are correct by running your test suite. Take a look!

![yardcheck](https://cloud.githubusercontent.com/assets/2085622/24262402/211ecfbe-0fb7-11e7-86f7-1b287298339f.gif)

## What is this?

When you write documentation like this

```ruby
# Validates the user
#
# @param user [User]
#
# @return [true,false]
# def valid?(user)
# ...
# end
```

You are saying that you are always going to be passing in a `User` instance and the method will always returns `true` or `false`.

`yardcheck` traces method invocations to observe the parameters and return values in your application while running your test suite. When your test suite finishes running we compare the observed types found while running your tests against the types in your documentation.

# Is this ready?

Kind of.

It is not ready to be run in CI to check your documentation and it may never be since tracing method calls is fairly slow. We also sometimes mess up. For example, if another method raises and error then all of the methods that bubble up that error without rescuing it will be marked as returning `nil`. This seems like a limitation of ruby's `TracePoint` right now.

It is very helpful though. It will find a lot of cases where your documentation isn't quite right and the output is clear. Install it and give it a try.
