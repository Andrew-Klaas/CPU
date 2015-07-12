// Romeo, Alyssa
// FALL 2014

#include <string>


using namespace std;

class Instruction {
public:
	string opcode;
	string dest;
	string sr1;
	string sr2;
	string new_code;

	void breakdown(string lc3b_command);

private:

};

