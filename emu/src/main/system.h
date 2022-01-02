/**
 * @file system.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Main system file
 * @date 2021-11-27
 * 
 */


namespace CPU {
    int start();
    void loop(void);
    unsigned cycle(void);
    unsigned cycleLog(void);
    unsigned cycleLogJson(void);
}