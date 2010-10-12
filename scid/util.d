/** Various useful utilities that don't really fit anywhere else.

    Authors:    Lars Tandle Kyllingstad
    Copyright:  Copyright (c) 2009, Lars T. Kyllingstad. All rights reserved.
    License:    Boost License 1.0
*/
module scid.util;


import std.math;
import std.traits;
import std.typecons;

import scid.core.testing;
import scid.core.traits;
import scid.exception;




/** Replaces real numbers that are close to zero by exactly zero.
    ---
    assert (chop(1.0) == 1.0);
    assert (chop(1e-20) == 0.0);
    ---
*/
Real chop(Real)(Real x, real threshold = 1e-10L) pure nothrow
    if (isFloatingPoint!(Real))
{
    if (fabs(x) < threshold) return 0.0;
    return x;
}

unittest
{
    check (chop(1.0) == 1.0);
    check (chop(1e-20) == 0.0);
}


/** Replaces all numbers in the given array that are close to zero
    by exactly zero. To chop the array in-place, pass the same array
    as both x and buffer.
    ---
    double[] a = [1.0, 1e-20, 2.0];
    double[] x = [1.0, 0.0, 2.0];
    auto b = chop(a);
    assert (b == x);
    chop(a, 1e-12L, a);
    assert (a == x);
    ---
*/
Real[] chop(Real) (Real[] x, real threshold = 1e-10L, Real[] buffer=null)
    nothrow
    if (isFloatingPoint!Real)
{
    if (buffer.length < x.length) buffer.length = x.length;

    foreach (i; 0 .. x.length)
        if (fabs(x[i]) < threshold)  buffer[i] = 0.0;
        else  buffer[i] = x[i];

    return buffer;
}

unittest
{
    real[] a = [1.0L, real.min_normal, 2.0];
    real[] x = [1.0L, 0.0, 2.0];

    auto b = chop(a);
    check (b == x);

    chop(a, 1e-12L, a);
    check (a == x);
}




/** Use bisection to find the point where a function starts returning NaN.

    Params:
        f               =   The function.
        xValid          =   A point where the function is known to
                            return a valid result.
        xNaN            =   A point where the function is known to
                            return NaN.
        fValid          =   (optional) The value of f at xValid.
        xTolerance      =   Success: When the absolute distance between
                            xValid and xNaN is less than this number,
                            the function returns.
        maxIterations   =   Failure: When the algorithm has failed to
                            produce a result after maxIterations bisections,
                            an exception is thrown.

    Returns:
    A tuple containing the values of xValid, xNaN, and fValid, where
    xValid and xNaN now satisfy the success criterion
    ---
    abs(xValid-xNaN) <= xTolerance
    ---

    Example:
    ---
    auto r = findNaN(&log, 1.0, -1.0, 1e-6);
    assert (r.xValid >= 0);
    assert (r.xNaN < 0);
    assert (abs(r.xValid - r.xNan) <= 1e-6);
    ---
*/
Tuple!(T, "xValid", T, "xNaN", ReturnType!Func, "fValid") findNaN(Func, T)
    (Func f, T xValid, T xNaN, T xTolerance, int maxIterations=40)
in
{
    assert (isNaN(f(xNaN)), "f(xNaN) is not NaN");
}
body
{
    auto fValid = f(xValid);
    return findNaN(f, xValid, xNaN, fValid, xTolerance, maxIterations);
}


/// ditto
Tuple!(T, "xValid", T, "xNaN", R, "fValid") findNaN(Func, T, R)
    (Func f, T xValid, T xNaN, R fValid, T xTolerance, int maxIterations=40)
    if (isUnaryFunction!(Func, R, T) && isFloatingPoint!R)
in
{
    assert (!isNaN(fValid), "fValid is NaN");
    assert (isNaN(f(xNaN)), "f(xNaN) is not NaN");
    assert (xTolerance > 0, "xTolerance must be positive");
}
body
{
    foreach (i; 0 .. maxIterations)
    {
        if (abs(xValid-xNaN) <= xTolerance)
            return typeof(return)(xValid, xNaN, fValid);

        immutable mid = (xValid + xNaN) / 2;
        immutable fmid = f(mid);
        if (isNaN(fmid))
        {
            xNaN = mid;
        }
        else
        {
            xValid = mid;
            fValid = fmid;
        }
    }

    enforceNE(false, NE.Limit);
    assert(0);
}

    
unittest
{
    auto r = findNaN(&log, 1.0, -1.0, 1e-6);
    check (!isNaN(r.fValid));
    check (log(r.xValid) == r.fValid);
    check (r.xValid >= 0);
    check (r.xNaN < 0);
    check (abs(r.xValid-r.xNaN) <= 1e-6);
}