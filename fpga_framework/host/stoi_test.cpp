#include <iostream>
#include <string>
 
int main()
{
    std::string s = "2688548965";
    long a = std::stoll(s);
    try {
        int i =  (int)(a);
        std::cout << i << std::endl;
    }
    catch (std::invalid_argument const &e) {
        std::cout << "Bad input: std::invalid_argument thrown" << std::endl;
    }
    catch (std::out_of_range const &e) {
        std::cout << "Integer overflow: std::out_of_range thrown" << std::endl;
    }
 
    return 0;
}