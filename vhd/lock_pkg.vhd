PACKAGE lock_pkg IS

   TYPE state_type IS (init, code_1, code_2, code_3);

   CONSTANT first_c  : integer := 4;    -- First code
   CONSTANT second_c : integer := 1;    -- Second code
   CONSTANT third_c  : integer := 6;    -- Third code
   CONSTANT fourth_c : integer := 9;    -- Fourth code

END lock_pkg;
