%%-------------------------------------------------------------------------
%% @doc Get {min, recommanded, max} Erlang version from compiler version
%% Look into https://github.com/erlang/otp/blob/maint/lib/compiler/vsn.mk
%% @end
%%-------------------------------------------------------------------------
-spec get_erlang_version(list()) -> {list(), list(), list()} | undefined.

get_erlang_version("7.6.4") -> {"23.1.1", "23.1.1", "23.1.1"};
get_erlang_version("7.6.3") -> {"23.1", "23.1", "23.1"};
get_erlang_version("7.6.2") -> {"23.0.3", "23.0.4", "23.0.4"};
get_erlang_version("7.6.1") -> {"23.0.1", "23.0.2", "23.0.2"};
get_erlang_version("7.6") -> {"23.0", "23.0", "23.0-rc3"};
get_erlang_version("7.5.4.1") -> {"22.3.4.3", "22.3.4.12", "22.3.4.12"};
get_erlang_version("7.5.4") -> {"22.3.1", "22.3.4.2", "22.3.4.2"};
get_erlang_version("7.5.3") -> {"22.3", "22.3", "22.3"};
get_erlang_version("7.5.2") -> {"22.2.7", "22.2.8", "22.2.8"};
get_erlang_version("7.5.1") -> {"22.2.3", "22.2.6", "22.2.6"};
get_erlang_version("7.5") -> {"22.2", "22.2.2", "22.2.2"};
get_erlang_version("7.4.9") -> {"22.1.7", "22.1.8.1", "22.1.8.1"};
get_erlang_version("7.4.8") -> {"22.1.6", "22.1.6", "22.1.6"};
get_erlang_version("7.4.7") -> {"22.1.4", "22.1.5", "22.1.5"};
get_erlang_version("7.4.6") -> {"22.1.1", "22.1.3", "22.1.3"};
get_erlang_version("7.4.5") -> {"22.1", "22.1", "22.1"};
get_erlang_version("7.4.4") -> {"22.0.7", "22.0.7", "22.0.7"};
get_erlang_version("7.4.3") -> {"22.0.6", "22.0.6", "22.0.6"};
get_erlang_version("7.4.2") -> {"22.0.3", "22.0.5", "22.0.5"};
get_erlang_version("7.4.1") -> {"22.0.2", "22.0.2", "22.0.2"};
get_erlang_version("7.4") -> {"22.0", "22.0.1", "22.0.1"};
get_erlang_version("7.3.2") -> {"21.3", "21.3.8.18", "21.3.8.18"};
get_erlang_version("7.3.1") -> {"21.2.3", "21.2.7", "21.2.7"};
get_erlang_version("7.3") -> {"21.2", "21.2.2", "21.2.2"};
get_erlang_version("7.2.7") -> {"21.1.2", "21.1.4", "21.1.4"};
get_erlang_version("7.2.6") -> {"21.1.1", "21.1.1", "21.1.1"};
get_erlang_version("7.2.5") -> {"21.1", "21.1", "21.1"};
get_erlang_version("7.2.4") -> {"21.0.9", "21.0.9", "21.0.9"};
get_erlang_version("7.2.3") -> {"21.0.5", "21.0.8", "21.0.8"};
get_erlang_version("7.2.2") -> {"21.0.2", "21.0.4", "21.0.4"};
get_erlang_version("7.2.1") -> {"21.0.1", "21.0.1", "21.0.1"};
get_erlang_version("7.2") -> {"21.0", "21.0", "21.0-rc2"};
get_erlang_version("7.1.5.2") -> {"20.3.8.9", "20.3.8.26", "20.3.8.26"};
get_erlang_version("7.1.5.1") -> {"20.3.8.5", "20.3.8.8", "20.3.8.8"};
get_erlang_version("7.1.5") -> {"20.3", "20.3.8.4", "20.3.8.4"};
get_erlang_version("7.1.4") -> {"20.2", "20.2.4", "20.2.4"};
get_erlang_version("7.1.3") -> {"20.1.1", "20.1.7.1", "20.1.7.1"};
get_erlang_version("7.1.2") -> {"20.1", "20.1", "20.1"};
get_erlang_version("7.1.1") -> {"20.0.3", "20.0.5", "20.0.5"};
get_erlang_version("7.1") -> {"20.0", "20.0.2", "20.0.2"};
get_erlang_version("7.0.4.1") -> {"19.3.6.3", "19.3.6.13", "19.3.6.13"};
get_erlang_version("7.0.4") -> {"19.3", "19.3.6.2", "19.3.6.2"};
get_erlang_version("7.0.3") -> {"19.2", "19.2.3.1", "19.2.3.1"};
get_erlang_version("7.0.2") -> {"19.1", "19.1.6.1", "19.1.6.1"};
get_erlang_version("7.0.1") -> {"19.0.2", "19.0.7", "19.0.7"};
get_erlang_version("7.0") -> {"19.0", "19.0.1", "19.0.1"};
get_erlang_version("6.0.3.1") -> {"18.3.4.6", "18.3.4.11", "18.3.4.11"};
get_erlang_version("6.0.3") -> {"18.3", "18.3.4.5", "18.3.4.5"};
get_erlang_version("6.0.2") -> {"18.2", "18.2.4.1", "18.2.4.1"};
get_erlang_version("6.0.1") -> {"18.1", "18.1.5", "18.1.5"};
get_erlang_version("6.0") -> {"18.0", "18.0.3", "18.0.3"};
get_erlang_version("5.0.4") -> {"17.5", "17.5.6.10", "17.5.6.10"};
get_erlang_version("5.0.3") -> {"17.4", "17.4.1", "18.0-rc1"};
get_erlang_version("5.0.2") -> {"17.3", "17.3.4", "17.3.4"};
get_erlang_version("5.0.1") -> {"17.1", "17.2.2", "17.2.2"};
get_erlang_version("5.0") -> {"17.0", "17.0.2", "17.0.2"};
get_erlang_version("4.9.4") -> {"17.0-rc1", "R16B03_yielding_binary_to_term", "R16B03_yielding_binary_to_term"};
get_erlang_version("4.9.3") -> {"R16B02", "R16B02", "R16B02"};
get_erlang_version("4.9.2") -> {"R16B01", "R16B01", "R16B01"};
get_erlang_version("4.9.1") -> {"R16B", "R16B", "R16B01_RC1"};
get_erlang_version("4.9") -> {"R16A_RELEASE_CANDIDATE", "R16A_RELEASE_CANDIDATE", "R16A_RELEASE_CANDIDATE"};
get_erlang_version("4.8.2") -> {"R15B02", "R15B03-1", "R15B03-1"};
get_erlang_version("4.8.1") -> {"R15B01", "R15B01", "R15B01"};
get_erlang_version("4.8") -> {"R15B", "R15B", "R15B"};
get_erlang_version("4.7.5.pre") -> {"R15A", "R15A", "R15A"};
get_erlang_version("4.7.5") -> {"R14B04", "R14B04", "R14B04"};
get_erlang_version("4.7.4") -> {"R14B03", "R14B03", "R14B03"};
get_erlang_version("4.7.3") -> {"R14B02", "R14B02", "R14B02"};
get_erlang_version("4.7.2") -> {"R14B01", "R14B01", "R14B01"};
get_erlang_version("4.7.1") -> {"R14B", "R14B", "R14B"};
get_erlang_version("4.7") -> {"R14A", "R14A", "R14A"};
get_erlang_version("4.6.5") -> {"R13B04", "R13B04", "R13B04"};
get_erlang_version("4.6.4") -> {"R13B03", "R13B03", "R13B03"};
get_erlang_version(_)           -> undefined.