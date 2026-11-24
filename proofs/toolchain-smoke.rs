use vstd::prelude::*;

verus! {
    fn successor(value: u8) -> (result: u8)
        requires value < u8::MAX,
        ensures result == value + 1,
    {
        value + 1
    }
}
