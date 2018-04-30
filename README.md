# crep

Support for Chamsys Remote Ethernet Protocol (CREP) and Chamsys Remote Protocol (CRP) for RubyMotion

## Installation

Add this line to your application's Gemfile:

    gem 'crep', github: 'pixlwave/crep'

And then execute:

    $ bundle

## Usage

CREP support is currently limited to sending only.
```ruby
crep = MQ::CREP.new
crep.send(my_string)
```

To parse strings into CRP use `MQ::CRP.parse`. If the parsing was successful, an array of CRP commands will be returned. Example strings supported are listed below.

Playback commands:
`playback 1 go`
`playback 2 stop`
`3 test`
`untest 4`

Head commands:
`select head 1`
`select heads 2 and 3`
`select 4 though 8`
`deselect 5 though 8 and 10 and 20`

`next head`
`previous`

`1 at 50%`
`2 and 6 at 70`
`channels 10 though 20 at 90`

`head 5 blue to 50`
`3 though 6 green to 20`
`1 and 5 red to 80`

`locate`
`at 65`
`red 20`
`green 30`
`blue 40`

`clear`
