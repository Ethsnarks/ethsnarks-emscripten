#include <libff/algebra/curves/alt_bn128/alt_bn128_pp.hpp>

#include <gmp.h>

#include <iostream>


int main( int argc, char **argv )
{
	typedef libff::alt_bn128_pp ppT;
	typedef libff::Fr<ppT> FieldT;
	ppT::init_public_params();

	if( GMP_NUMB_BITS != 32 ) {
		std::cerr << "FAIL: GMP_NUMB_BITS != 32, it is " << GMP_NUMB_BITS << "\n";
		return 1;
	}

	if( sizeof(mp_limb_t) != 4 ) {
		std::cerr << "FAIL: sizeof(mp_limb_t) != 4, it is " << sizeof(mp_limb_t) << "\n";
		return 2;
	}

	const char *value_hex_str = "0x2a11cd2f23f4e729cd410542a6e805d70ca69b1686d24b1d6ef8b612963c70e5";

	// Verify parsing a big int from hex str
	mpz_t value;
	int value_error;
	::mpz_init(value);
	value_error = ::mpz_set_str(value, value_hex_str, 0);
	if( value_error ) {
		std::cerr << "FAIL: failed to set mpz value\n";
		return 3;
	}
	// Ensure matches
	char *value_out_hex = mpz_get_str(NULL, 16, value);
	if( 0 != strcmp(&value_hex_str[2], value_out_hex) )
	{
		std::cerr << "FAIL: falied to retrieve same MPZ value\n";
		return 4;
	}
	::free(value_out_hex);

	// Verify field element
	FieldT value_Fr(value);
	value_Fr.print();
	::mpz_clear(value);

	return 0;
}