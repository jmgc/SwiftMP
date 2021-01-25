//
//  CminigmpzTests.m
//  SwiftMP
//
//  Created by José María Gómez Cama on 18/01/2021.
//

#import <XCTest/XCTest.h>
#include <Cmpfr.h>

void
testfree (void *p)
{
    void (*freefunc) (void *, size_t);
    mp_get_memory_functions (NULL, NULL, &freefunc);

    freefunc (p, 0);
}

void
dump (const char *label, const mpz_t x)
{
    char *buf = mpz_get_str (NULL, 16, x);
    fprintf (stderr, "%s: %s\n", label, buf);
    testfree (buf);
}

@interface CminigmpTests : XCTestCase

@end

@implementation CminigmpTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testCmpfrAvailability {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    mpfr_t a, b, res, ref;

    mpfr_init(a);
    mpfr_init(b);
    mpfr_init(res);
    mpfr_init(ref);

    mpfr_set_si(a, 23, MPFR_RNDD);
    mpfr_set_si(b, 54, MPFR_RNDD);
    mpfr_set_si(ref, 77, MPFR_RNDD);

    mpfr_add(res, a, b, MPFR_RNDU);
    XCTAssert(mpfr_cmp(res, ref) == 0);
    mpfr_clear (a);
    mpfr_clear (b);
    mpfr_clear (res);
    mpfr_clear (ref);

}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
