# sockaddr considered dangerous

`sockaddr_in6` is 12 bytes longer than `sockaddr` and `sockaddr`. This means casting `sockaddr` pointers to/from `sockaddr_in6` pointers can be unsafe.




```
schwa@mote ~> swift
Welcome to Apple Swift version 2.1.1 (swiftlang-700.1.101.15 clang-700.1.81). Type :help for assistance.
  1> import Darwin
  2> sizeof(sockaddr)
$R0: Int = 16
  3> sizeof(sockaddr_in)
$R1: Int = 16
  4> sizeof(sockaddr_in6)
$R2: Int = 28
```