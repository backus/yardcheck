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

For example, here is part of the output from the demo gif at the top of the README:

> Expected `Dry::Types::Array::Member#try` to receive `an object responding to #call` for `block` but observed `NilClass`
>
> ```
> source: lib/dry/types/array/member.rb:35
> tests:
>   - ./spec/dry/types/compiler_spec.rb:184
>   - ./spec/dry/types/sum_spec.rb:47
>   - ./spec/dry/types/sum_spec.rb:60
>   - ./spec/dry/types/types/form_spec.rb:235
>   - ./spec/dry/types/types/form_spec.rb:240
>   - ./spec/dry/types/types/form_spec.rb:245
>   - ./spec/dry/types/types/form_spec.rb:250
>   - ./spec/dry/types/types/json_spec.rb:69
> ```
>
>
> ```ruby
> # @param [Array, Object] input
> # @param [#call] block
> # @yieldparam [Failure] failure
> # @yieldreturn [Result]
> # @return [Result]
> def try(input, &block)
>   if input.is_a?(::Array)
>     result = call(input, :try)
>     output = result.map(&:input)
>
>     if result.all?(&:success?)
>       success(output)
>     else
>       failure = failure(output, result.select(&:failure?))
>       block ? yield(failure) : failure
>     end
>   else
>     failure = failure(input, "#{input} is not an array")
>     block ? yield(failure) : failure
>   end
> end
> ```

Yardcheck is doing some cool things here:

1. It outputs the offending method and documentation to give you immediate context. It also gives you the path and line number if you want to open up that file.
2. It understands that the YARD documentation `@param [#call]` means a duck typed object that responds to the method `#call`.
3. It tells you that it actually observed cases where the param was `nil` which does not respond to `#call`.
4. It lists all of the tests that observed a `nil` block param.

In this case I would update the documentation to be `@param [#call, nil] block`

## Is this ready?

Kind of.

It is not ready to be run in CI to check your documentation and it may never be since tracing method calls is fairly slow. We also sometimes mess up. For example, if another method raises an error then all of the methods that bubble up that error without rescuing it will be marked as returning `nil`. This seems like a limitation of ruby's `TracePoint` right now.

It is very helpful though. It will find a lot of cases where your documentation isn't quite right and the output is clear. Install it and give it a try.

## Install

You probably could have guessed this, but to install just run

```
$ gem install yardcheck
```

Or add this to your Gemfile

```
gem 'yardcheck'
```

