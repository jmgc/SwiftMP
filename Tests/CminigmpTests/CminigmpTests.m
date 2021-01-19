//
//  CminigmpzTests.m
//  SwiftMP
//
//  Created by José María Gómez Cama on 18/01/2021.
//

#import <XCTest/XCTest.h>
#include <Cminigmp.h>

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

- (void)testCminigmpAvailability {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    unsigned i;
    mpz_t a, b, res, ref;

    mpz_init_set_si(a, 23);
    mpz_init_set_si(b, 54);
    mpz_init(res);
    mpz_init_set_si(ref, 77);

    mpz_add(res, a, b);
    if (mpz_cmp (res, ref))
    {
        fprintf (stderr, "mpz_add failed:\n");
        dump ("a", a);
        dump ("b", b);
        dump ("r", res);
        dump ("ref", ref);
        abort ();
    }
    mpz_clear (a);
    mpz_clear (b);
    mpz_clear (res);
    mpz_clear (ref);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
