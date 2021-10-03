/**
 * This is a test for basic instruction pipeline functionality
 *
 */

#include "../common/log.h"
#include "../cpu/pipeline.h"

InstructionPipeline ip;

void Update(unsigned n = 1)
{
    for (unsigned i = 0; i < n; i++) {
        ip.log();
        ip.Update();
        ip.UpdatePorts();
    }
    Log::log("\n");
}

int main()
{
    ip.i_ClockEnable = 1;
    ip.i_InstructionAddress = 0;
  
    ip.i_InstructionInput = 0x55555537;
    Update();

    ip.i_InstructionInput = 0x55555517;
    Update();

    ip.i_InstructionInput = 0x0000056f;
    Update();

    ip.i_InstructionInput = 0x55550567;
    Update();

    ip.i_InstructionInput = 0x08a50263;
    Update();

    ip.i_InstructionInput = 0x08a51063;
    Update();

    ip.i_InstructionInput = 0x06a54e63;
    Update();

    ip.i_InstructionInput = 0x06a55c63;
    Update();

    ip.i_InstructionInput = 0x06a56a63;
    Update();

    ip.i_InstructionInput = 0x06a57863;
    Update();

    ip.i_InstructionInput = 0x55550503;
    Update();

    ip.i_InstructionInput = 0x55551503;
    Update();

    ip.i_InstructionInput = 0x55552503;
    Update();

    ip.i_InstructionInput = 0x55554503;
    Update();

    ip.i_InstructionInput = 0x55555503;
    Update();

    ip.i_InstructionInput = 0x54a50aa3;
    Update();

    ip.i_InstructionInput = 0x54a51aa3;
    Update();

    ip.i_InstructionInput = 0x54a52aa3;
    Update();

    ip.i_InstructionInput = 0x55550513;
    Update();

    ip.i_InstructionInput = 0x55552513;
    Update();

    ip.i_InstructionInput = 0x55553513;
    Update();

    ip.i_InstructionInput = 0x55554513;
    Update();

    ip.i_InstructionInput = 0x55556513;
    Update();

    ip.i_InstructionInput = 0x55557513;
    Update();

    ip.i_InstructionInput = 0x01551513;
    Update();

    ip.i_InstructionInput = 0x01555513;
    Update();

    ip.i_InstructionInput = 0x41555513;
    Update();

    ip.i_InstructionInput = 0x00a50533;
    Update();

    ip.i_InstructionInput = 0x40a50533;
    Update();

    ip.i_InstructionInput = 0x00a51533;
    Update();

    ip.i_InstructionInput = 0x00a52533;
    Update();

    ip.i_InstructionInput = 0x00a53533;
    Update();

    ip.i_InstructionInput = 0x00a54533;
    Update();

    ip.i_InstructionInput = 0x00a55533;
    Update();

    ip.i_InstructionInput = 0x40a55533;
    Update();

    ip.i_InstructionInput = 0x00a56533;
    Update();

    ip.i_InstructionInput = 0x00a57533;
    Update();

    return 0;
}