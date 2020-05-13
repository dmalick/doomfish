using GLFW

# includes an enum to wrap the GLFW key bindings,

@enum KeyAction begin
    key_press = Int(GLFW.PRESS)
    key_release = Int(GLFW.RELEASE)
    key_repeat = Int(GLFW.REPEAT)
    key_idle
end

@enum Key begin
     KEY_UNKNOWN = -1

     KEY_SPACE = 32

     KEY_APOSTROPHE = 39

     KEY_COMMA = 44

     KEY_MINUS = 45

     KEY_PERIOD = 46

     KEY_SLASH = 47

     KEY_0 = 48

     KEY_1 = 49

     KEY_2 = 50

     KEY_3 = 51

     KEY_4 = 52

     KEY_5 = 53

     KEY_6 = 54

     KEY_7 = 55

     KEY_8 = 56

     KEY_9 = 57

     KEY_SEMICOLON = 59

     KEY_EQUAL = 61

     KEY_A = 65

     KEY_B = 66

     KEY_C = 67

     KEY_D = 68

     KEY_E = 69

     KEY_F = 70

     KEY_G = 71

     KEY_H = 72

     KEY_I = 73

     KEY_J = 74

     KEY_K = 75

     KEY_L = 76

     KEY_M = 77

     KEY_N = 78

     KEY_O = 79

     KEY_P = 80

     KEY_Q = 81

     KEY_R = 82

     KEY_S = 83

     KEY_T = 84

     KEY_U = 85

     KEY_V = 86

     KEY_W = 87

     KEY_X = 88

     KEY_Y = 89

     KEY_Z = 90

     KEY_LEFT_BRACKET = 91

     KEY_BACKSLASH = 92

     KEY_RIGHT_BRACKET = 93

     KEY_GRAVE_ACCENT = 96

     KEY_WORLD_1 = 161

     KEY_WORLD_2 = 162

     KEY_ESCAPE = 256

     KEY_ENTER = 257

     KEY_TAB = 258

     KEY_BACKSPACE = 259

     KEY_INSERT = 260

     KEY_DELETE = 261

     KEY_RIGHT = 262

     KEY_LEFT = 263

     KEY_DOWN = 264

     KEY_UP = 265

     KEY_PAGE_UP = 266

     KEY_PAGE_DOWN = 267

     KEY_HOME = 268

     KEY_END = 269

     KEY_CAPS_LOCK = 280

     KEY_SCROLL_LOCK = 281

     KEY_NUM_LOCK = 282

     KEY_PRINT_SCREEN = 283

     KEY_PAUSE = 284

     KEY_F1 = 290

     KEY_F2 = 291

     KEY_F3 = 292

     KEY_F4 = 293

     KEY_F5 = 294

     KEY_F6 = 295

     KEY_F7 = 296

     KEY_F8 = 297

     KEY_F9 = 298

     KEY_F10 = 299

     KEY_F11 = 300

     KEY_F12 = 301

     KEY_F13 = 302

     KEY_F14 = 303

     KEY_F15 = 304

     KEY_F16 = 305

     KEY_F17 = 306

     KEY_F18 = 307

     KEY_F19 = 308

     KEY_F20 = 309

     KEY_F21 = 310

     KEY_F22 = 311

     KEY_F23 = 312

     KEY_F24 = 313

     KEY_F25 = 314

     KEY_KP_0 = 320

     KEY_KP_1 = 321

     KEY_KP_2 = 322

     KEY_KP_3 = 323

     KEY_KP_4 = 324

     KEY_KP_5 = 325

     KEY_KP_6 = 326

     KEY_KP_7 = 327

     KEY_KP_8 = 328

     KEY_KP_9 = 329

     KEY_KP_DECIMAL = 330

     KEY_KP_DIVIDE = 331

     KEY_KP_MULTIPLY = 332

     KEY_KP_SUBTRACT = 333

     KEY_KP_ADD = 334

     KEY_KP_ENTER = 335

     KEY_KP_EQUAL = 336

     KEY_LEFT_SHIFT = 340

     KEY_LEFT_CONTROL = 341

     KEY_LEFT_ALT = 342

     KEY_LEFT_SUPER = 343

     KEY_RIGHT_SHIFT = 344

     KEY_RIGHT_CONTROL = 345

     KEY_RIGHT_ALT = 346

     KEY_RIGHT_SUPER = 347

     KEY_MENU = 348
end
KEY_LAST =  KEY_MENU

binaryKeyState  = Dict(
     KEY_UNKNOWN  => false,

     KEY_SPACE  => false,

     KEY_APOSTROPHE  => false,

     KEY_COMMA  => false,

     KEY_MINUS  => false,

     KEY_PERIOD  => false,

     KEY_SLASH  => false,

     KEY_0  => false,

     KEY_1  => false,

     KEY_2  => false,

     KEY_3  => false,

     KEY_4  => false,

     KEY_5  => false,

     KEY_6  => false,

     KEY_7  => false,

     KEY_8  => false,

     KEY_9  => false,

     KEY_SEMICOLON  => false,

     KEY_EQUAL  => false,

     KEY_A  => false,

     KEY_B  => false,

     KEY_C  => false,

     KEY_D  => false,

     KEY_E  => false,

     KEY_F  => false,

     KEY_G  => false,

     KEY_H  => false,

     KEY_I  => false,

     KEY_J  => false,

     KEY_K  => false,

     KEY_L  => false,

     KEY_M  => false,

     KEY_N  => false,

     KEY_O  => false,

     KEY_P  => false,

     KEY_Q  => false,

     KEY_R  => false,

     KEY_S  => false,

     KEY_T  => false,

     KEY_U  => false,

     KEY_V  => false,

     KEY_W  => false,

     KEY_X  => false,

     KEY_Y  => false,

     KEY_Z  => false,

     KEY_LEFT_BRACKET  => false,

     KEY_BACKSLASH  => false,

     KEY_RIGHT_BRACKET  => false,

     KEY_GRAVE_ACCENT  => false,

     KEY_WORLD_1  => false,

     KEY_WORLD_2  => false,

     KEY_ESCAPE  => false,

     KEY_ENTER  => false,

     KEY_TAB  => false,

     KEY_BACKSPACE  => false,

     KEY_INSERT  => false,

     KEY_DELETE  => false,

     KEY_RIGHT  => false,

     KEY_LEFT  => false,

     KEY_DOWN  => false,

     KEY_UP  => false,

     KEY_PAGE_UP  => false,

     KEY_PAGE_DOWN  => false,

     KEY_HOME  => false,

     KEY_END  => false,

     KEY_CAPS_LOCK  => false,

     KEY_SCROLL_LOCK  => false,

     KEY_NUM_LOCK  => false,

     KEY_PRINT_SCREEN  => false,

     KEY_PAUSE  => false,

     KEY_F1  => false,

     KEY_F2  => false,

     KEY_F3  => false,

     KEY_F4  => false,

     KEY_F5  => false,

     KEY_F6  => false,

     KEY_F7  => false,

     KEY_F8  => false,

     KEY_F9  => false,

     KEY_F10  => false,

     KEY_F11  => false,

     KEY_F12  => false,

     KEY_F13  => false,

     KEY_F14  => false,

     KEY_F15  => false,

     KEY_F16  => false,

     KEY_F17  => false,

     KEY_F18  => false,

     KEY_F19  => false,

     KEY_F20  => false,

     KEY_F21  => false,

     KEY_F22  => false,

     KEY_F23  => false,

     KEY_F24  => false,

     KEY_F25  => false,

     KEY_KP_0  => false,

     KEY_KP_1  => false,

     KEY_KP_2  => false,

     KEY_KP_3  => false,

     KEY_KP_4  => false,

     KEY_KP_5  => false,

     KEY_KP_6  => false,

     KEY_KP_7  => false,

     KEY_KP_8  => false,

     KEY_KP_9  => false,

     KEY_KP_DECIMAL  => false,

     KEY_KP_DIVIDE  => false,

     KEY_KP_MULTIPLY  => false,

     KEY_KP_SUBTRACT  => false,

     KEY_KP_ADD  => false,

     KEY_KP_ENTER  => false,

     KEY_KP_EQUAL  => false,

     KEY_LEFT_SHIFT  => false,

     KEY_LEFT_CONTROL  => false,

     KEY_LEFT_ALT  => false,

     KEY_LEFT_SUPER  => false,

     KEY_RIGHT_SHIFT  => false,

     KEY_RIGHT_CONTROL  => false,

     KEY_RIGHT_ALT  => false,

     KEY_RIGHT_SUPER  => false,

     KEY_MENU  => false,

     KEY_LAST => false,

   )

keyActionState  = Dict(

   KEY_UNKNOWN  => key_idle,

   KEY_SPACE  => key_idle,

   KEY_APOSTROPHE  => key_idle,

   KEY_COMMA  => key_idle,

   KEY_MINUS  => key_idle,

   KEY_PERIOD  => key_idle,

   KEY_SLASH  => key_idle,

   KEY_0  => key_idle,

   KEY_1  => key_idle,

   KEY_2  => key_idle,

   KEY_3  => key_idle,

   KEY_4  => key_idle,

   KEY_5  => key_idle,

   KEY_6  => key_idle,

   KEY_7  => key_idle,

   KEY_8  => key_idle,

   KEY_9  => key_idle,

   KEY_SEMICOLON  => key_idle,

   KEY_EQUAL  => key_idle,

   KEY_A  => key_idle,

   KEY_B  => key_idle,

   KEY_C  => key_idle,

   KEY_D  => key_idle,

   KEY_E  => key_idle,

   KEY_F  => key_idle,

   KEY_G  => key_idle,

   KEY_H  => key_idle,

   KEY_I  => key_idle,

   KEY_J  => key_idle,

   KEY_K  => key_idle,

   KEY_L  => key_idle,

   KEY_M  => key_idle,

   KEY_N  => key_idle,

   KEY_O  => key_idle,

   KEY_P  => key_idle,

   KEY_Q  => key_idle,

   KEY_R  => key_idle,

   KEY_S  => key_idle,

   KEY_T  => key_idle,

   KEY_U  => key_idle,

   KEY_V  => key_idle,

   KEY_W  => key_idle,

   KEY_X  => key_idle,

   KEY_Y  => key_idle,

   KEY_Z  => key_idle,

   KEY_LEFT_BRACKET  => key_idle,

   KEY_BACKSLASH  => key_idle,

   KEY_RIGHT_BRACKET  => key_idle,

   KEY_GRAVE_ACCENT  => key_idle,

   KEY_WORLD_1  => key_idle,

   KEY_WORLD_2  => key_idle,

   KEY_ESCAPE  => key_idle,

   KEY_ENTER  => key_idle,

   KEY_TAB  => key_idle,

   KEY_BACKSPACE  => key_idle,

   KEY_INSERT  => key_idle,

   KEY_DELETE  => key_idle,

   KEY_RIGHT  => key_idle,

   KEY_LEFT  => key_idle,

   KEY_DOWN  => key_idle,

   KEY_UP  => key_idle,

   KEY_PAGE_UP  => key_idle,

   KEY_PAGE_DOWN  => key_idle,

   KEY_HOME  => key_idle,

   KEY_END  => key_idle,

   KEY_CAPS_LOCK  => key_idle,

   KEY_SCROLL_LOCK  => key_idle,

   KEY_NUM_LOCK  => key_idle,

   KEY_PRINT_SCREEN  => key_idle,

   KEY_PAUSE  => key_idle,

   KEY_F1  => key_idle,

   KEY_F2  => key_idle,

   KEY_F3  => key_idle,

   KEY_F4  => key_idle,

   KEY_F5  => key_idle,

   KEY_F6  => key_idle,

   KEY_F7  => key_idle,

   KEY_F8  => key_idle,

   KEY_F9  => key_idle,

   KEY_F10  => key_idle,

   KEY_F11  => key_idle,

   KEY_F12  => key_idle,

   KEY_F13  => key_idle,

   KEY_F14  => key_idle,

   KEY_F15  => key_idle,

   KEY_F16  => key_idle,

   KEY_F17  => key_idle,

   KEY_F18  => key_idle,

   KEY_F19  => key_idle,

   KEY_F20  => key_idle,

   KEY_F21  => key_idle,

   KEY_F22  => key_idle,

   KEY_F23  => key_idle,

   KEY_F24  => key_idle,

   KEY_F25  => key_idle,

   KEY_KP_0  => key_idle,

   KEY_KP_1  => key_idle,

   KEY_KP_2  => key_idle,

   KEY_KP_3  => key_idle,

   KEY_KP_4  => key_idle,

   KEY_KP_5  => key_idle,

   KEY_KP_6  => key_idle,

   KEY_KP_7  => key_idle,

   KEY_KP_8  => key_idle,

   KEY_KP_9  => key_idle,

   KEY_KP_DECIMAL  => key_idle,

   KEY_KP_DIVIDE  => key_idle,

   KEY_KP_MULTIPLY  => key_idle,

   KEY_KP_SUBTRACT  => key_idle,

   KEY_KP_ADD  => key_idle,

   KEY_KP_ENTER  => key_idle,

   KEY_KP_EQUAL  => key_idle,

   KEY_LEFT_SHIFT  => key_idle,

   KEY_LEFT_CONTROL  => key_idle,

   KEY_LEFT_ALT  => key_idle,

   KEY_LEFT_SUPER  => key_idle,

   KEY_RIGHT_SHIFT  => key_idle,

   KEY_RIGHT_CONTROL  => key_idle,

   KEY_RIGHT_ALT  => key_idle,

   KEY_RIGHT_SUPER  => key_idle,

   KEY_MENU  => key_idle,

   KEY_LAST => key_idle,

 )

struct KeyState
    binaryState::Dict{Key, Bool}
    actionState::Dict{Key, KeyAction}
end
KeyState() = KeyState( binaryKeyState, keyActionState )
