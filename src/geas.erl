%%%-------------------------------------------------------------------
%%% File:      geas.erl
%%% @author    Eric Pailleau <geas@crownedgrouse.com>
%%% @copyright 2014 crownedgrouse.com
%%% @doc  
%%% Guess Erlang Application Scattering
%%% @end  
%%%
%%% Permission to use, copy, modify, and/or distribute this software
%%% for any purpose with or without fee is hereby granted, provided
%%% that the above copyright notice and this permission notice appear
%%% in all copies.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
%%% WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
%%% WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
%%% AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
%%% CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
%%% LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
%%% NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
%%% CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
%%%
%%% Created : 2014-09-07
%%%-------------------------------------------------------------------
-module(geas).
-author("Eric Pailleau <geas@crownedgrouse.com>").

% rebar2 plugin
-export([geas/2]).

% Other exported functions for non plugin use
-export([info/1, what/1, offending/1, compat/1, compat/2, guilty/1]).

-include("geas_db.hrl").

-define(COMMON_DIR(Dir),
            AppFile   = get_app_file(Dir),
            % Informations inventory
            {AppName, Version , Desc}  = get_app_infos(AppFile),
            AppType   = get_app_type(AppFile, Dir),
            Native    = is_native(Dir),
            Arch      = get_arch(Native, Dir),
            Word      = get_word(),
            AppBeam   = filename:join(Dir, atom_to_list(AppName)++".beam"),
            Date      = get_date(AppBeam),
            Author    = get_author(AppBeam),
            Os        = get_os(),
            %Erts      = get_erts_version(AppBeam),
            Comp      = get_compile_version(AppBeam),
            Erlang    = get_erlang_version(Comp)
).

%%-------------------------------------------------------------------------
%% @doc Return infos after application directory analysis
%% @end
%%-------------------------------------------------------------------------
-spec info(list()) -> tuple().

info(Dir) when is_list(Dir) -> 
        {ok, CurPwd} = file:get_cwd(),
        try
            % Fatal tests
            is_valid_dir(Dir),
            is_valid_erlang_project(Dir),
            % Variables
            EbinDir   = filename:join(Dir, "ebin"),
            CsrcDir   = filename:join(Dir, "c_src"),
            Driver    = is_using_driver(CsrcDir),
            ?COMMON_DIR(EbinDir) ,
            Compat    = get_erlang_compat(Dir),
            % Commands to be done in Dir
            ok = file:set_cwd(Dir),

            VCS       = get_vcs(),
            VcsVsn    = get_vcs_version(VCS),
            VcsUrl    = get_vcs_url(VCS),

            Maint     = get_maintainer(VCS),
            CL        = get_changelog(),
            RN        = get_releasenotes(),

            {ok,
            [{name, AppName},
             {version, Version}, 
             {description, Desc},
             {type, AppType},
             {datetime, Date},
             {native, Native},
             {arch, Arch},
             {os, Os},
             {word, Word},
             {compile, Comp},
             {erlang, Erlang},
             {compat, Compat},
             {author, Author},             
             {vcs, {VCS, VcsVsn, VcsUrl}},
             {maintainer, Maint},
             {changelog, CL},
             {releasenotes, RN},
             {driver, Driver}]}
       catch
           throw:Reason -> {error, Reason}
       after
           ok = file:set_cwd(CurPwd)
       end.

%%-------------------------------------------------------------------------
%% @doc Return infos on .beam file(s) only
%% @end
%%-------------------------------------------------------------------------
-spec what(list()) -> tuple().

what(Dir) when is_list(Dir) -> 
        {ok, CurPwd} = file:get_cwd(),
        try
            Output = case filelib:is_regular(Dir) of  
                        true  -> what_beam(Dir);
                        false -> what_dir(Dir)
                     end,
            Output
        catch
           throw:Reason -> {error, Reason}
        after
           ok = file:set_cwd(CurPwd)
        end.

%%-------------------------------------------------------------------------
%% @doc Return infos on .beam file(s) only
%% @end
%%-------------------------------------------------------------------------
-spec what_dir(list()) -> tuple().

what_dir(Dir) ->           
            ?COMMON_DIR(Dir) ,
            Compat    = get_erlang_compat(Dir),
            {ok,
                [{name, AppName},
                 {version, Version}, 
                 {description, Desc},
                 {type, AppType},
                 {datetime, Date},
                 {native, Native},
                 {arch, Arch},
                 {os, Os},
                 {word, Word},
                 {compile, Comp},
                 {erlang, Erlang},
                 {compat, Compat},
                 {author, Author}]}.

%%-------------------------------------------------------------------------
%% @doc what/1 on a single beam file
%% @end
%%-------------------------------------------------------------------------
-spec what_beam(list()) -> tuple().

what_beam(File) ->         
			{Name, Version} = case beam_lib:version(File) of
									{ok,{N,[V]}} -> {N, V} ;
			    					_            -> {filename:basename(File, ".beam"), undefined}
							  end,
                
            AppType   = get_app_type_beam(File),
            Native    = is_native_from_file(File),
            Arch      = get_arch_from_file(File),
            Word      = get_word(),
            Date      = get_date(File),
            Author    = get_author(File),
            Os        = get_os(),
            %Erts      = get_erts_version(AppBeam),
            Comp      = get_compile_version(File),
            Erlang    = get_erlang_version(Comp),
            Compat    = get_erlang_compat_file(File),

            {ok,
                [{name, Name},
                 {version, Version}, 
                 {type, AppType},
                 {datetime, Date},
                 {native, Native},
                 {arch, Arch},
                 {os, Os},
                 {word, Word},
                 {compile, Comp},
                 {erlang, Erlang},
                 {compat, Compat},
                 {author, Author}]}.

%%-------------------------------------------------------------------------
%% @doc Is the directory existing and readable ?
%% @end
%%-------------------------------------------------------------------------
-spec is_valid_dir(list()) -> ok | error.

is_valid_dir(Dir) -> 
    case filelib:is_dir(Dir) of
      true  -> case file:list_dir(Dir) of
                    {ok, []} ->  throw("Empty directory : "++Dir);
                    {ok, _}  ->  ok;
                    {error, eacces}  -> throw("Access denied : "++Dir), error;
                    {error, E}       -> throw(io_lib:format("Error : ~p",[E])),
                                        error
               end;
      false -> throw("Directory not found : "++Dir), error
    end.

%%-------------------------------------------------------------------------
%% @doc Does this directory contains a valid Erlang project ?
%% @end
%%-------------------------------------------------------------------------
-spec is_valid_erlang_project(list()) -> atom().

is_valid_erlang_project(Dir) ->
    % Workaround for GEAS_USE_SRC : some projects have subdirectories under src/.
    % example :  https://github.com/nitrogen/simple_bridge
    % Bring upper directory in such case
    Dir2 = case filename:basename(Dir) of
			 "src" -> filename:dirname(Dir) ;
			 _     -> Dir
		   end,
    {ok, L} = file:list_dir(Dir2),
	% When using beam files, do not require src/ to be there
	Src  = case os:getenv("GEAS_USE_SRC") of
		   		false -> true ;
		   		"0"   -> true ;
		   		"1"   -> lists:any(fun(X) -> (X =:= "src") end, L)
	       end,
    % When using source files, do not require ebin/ to be there
    Ebin = case os:getenv("GEAS_USE_SRC") of
		   		false -> lists:any(fun(X) -> (X =:= "ebin") end, L) ;
		   		"0"   -> lists:any(fun(X) -> (X =:= "ebin") end, L) ;
		   		"1"   -> true
	       end,
    case ((Src =:= true) and (Ebin =:= true)) of
        true  -> ok ;
        false -> throw("Invalid Erlang project : "++Dir2) , error
    end.

%%-------------------------------------------------------------------------
%% @doc Get application type (escript / otp / app / lib )
%% esc : (escript) Contain main/1 in exported functions.
%% otp : Contains 'mod' in .app file
%%       {application, ch_app,
%%       [{mod, {ch_app,[]}}]}.
%%       And start/2 and stop/1 in exported functions.
%% app : Contain a start/0 or start/1 and a stop/0 or stop/1 .
%% lib : library application (one or several modules).
%% @end
%%-------------------------------------------------------------------------
-spec get_app_type(list(), list()) -> otp | app | lib | esc .

get_app_type(AppFile, Ebindir) ->
        % 'otp' ?
        % Search 'mod' in .app file
        {ok,[{application, App, L}]} = file:consult(AppFile),
        case lists:keyfind(mod, 1, L) of
             {mod, {Callback, _}} -> 
                     Beam = filename:join(Ebindir, Callback),
                     case filelib:is_regular(Beam ++ ".beam") of
                          true -> % start/2 and stop/1 ?
                                  {ok,{_,[{exports, L2}]}} = beam_lib:chunks(Beam, [exports]),
                                  case (lists:member({start, 2}, L2) and 
                                    lists:member( {stop, 1}, L2)) of
                                        true  -> otp ;
                                        false -> lib   % Strange but... anyway.
                                  end;
                          false -> mis
                     end;
             false -> % 'app' ?
                      Beam = filename:join(Ebindir, atom_to_list(App)),
                      case filelib:is_regular(Beam ++ ".beam") of
                          true -> {ok,{_,[{exports, L3}]}} = beam_lib:chunks(Beam, [exports]),
                                  case ((lists:member({start, 0}, L3) or lists:member({start, 1}, L3)) and
                                       (lists:member( {stop, 0}, L3) or lists:member( {stop, 1}, L3))) of
                                            true  -> app ;
                                            false -> % 'escript' ?
                                                    case lists:member({main, 1}, L3) of
                                                            true  -> esc ;
                                                            false -> lib 
                                                    end  
                                  end;
                          false -> mis
                     end
        end.

%%-------------------------------------------------------------------------
%% @doc  get type from file
%% @end
%%-------------------------------------------------------------------------
-spec get_app_type_beam(list()) -> atom().

get_app_type_beam(File) ->
		case filename:extension(File) of
			".erl" -> undefined ;
			_      -> 
                 % start/2 and stop/1 ?
                 {ok,{_,[{exports, L}]}} = beam_lib:chunks(File, [exports]),
                     case (lists:member({start, 2}, L) and 
                           lists:member( {stop, 1}, L)) of
                            true  -> otp ;
                            false -> case ((lists:member({start, 0}, L) or lists:member({start, 1}, L)) and
                                           (lists:member( {stop, 0}, L) or lists:member( {stop, 1}, L))) of
                                            true  -> app ;
                                            false -> % 'escript' ?
                                                     case lists:member({main, 1}, L) of
                                                        true  -> esc ;
                                                        false -> lib 
                                                     end  
                                     end
                     end
	   end.

%%-------------------------------------------------------------------------
%% @doc Find .app filename in ebin 
%% @end
%%-------------------------------------------------------------------------
-spec get_app_file(list()) -> list().

get_app_file(Dir) -> Check = case os:getenv("GEAS_USE_SRC") of
							   false -> true ;
							   "0"   -> true ;
							   "1"   -> false
				             end,
                     case Check of
						  true -> 
					 				case filelib:wildcard("*.app", Dir) of
                        				[]    -> throw("Application Resource File (.app) not found. Aborting."),
                                 				 "" ;
                        				[App] -> filename:join(Dir, App) ;
                        				_     -> throw("More than one .app file found in : "++ Dir), "" 		
									end;
						  false ->  % Workaround for subdirectories in src/							
									DirSrc = case filename:basename(Dir) of
												  "src" -> Dir ;
												  _     -> filename:join(filename:dirname(Dir),"src")
											 end,					
									case filelib:wildcard("*.app.src", DirSrc) of
                        				[]    -> throw("Application Resource File (.app.src) not found. Aborting."),
                                 				 "" ;
                        				[App] -> filename:join(DirSrc, App) ;
                        				_     -> throw("More than one .app.src file found in : "++ DirSrc), "" 		
									end
                     end.
                        
%%-------------------------------------------------------------------------
%% @doc 
%% os:type() -> {Osfamily, Osname}
%% Types:
%%       Osfamily = unix | win32 | ose
%%       Osname = atom()
%%
%% os:version() -> VersionString | {Major, Minor, Release}
%% @end
%%-------------------------------------------------------------------------
-spec get_os() -> tuple().

get_os() -> {A, B} = os:type(),
            V = case os:version() of
                    {X, Y, Z} -> integer_to_list(X)++"."++integer_to_list(Y)++
                                 "."++integer_to_list(Z) ;
                    C         -> C
                end,
            {A, B, V}.

%%-------------------------------------------------------------------------
%% @doc Get the VCS of the project
%% 
%% Vcs-Arch,               Hum... Who cares ?
%% Vcs-Bzr (Bazaar),       directory : ../trunk ! 
%% Vcs-Cvs,                directory : CVS
%% Vcs-Darcs,              directory : _darcs
%% Vcs-Git,                directory : .git
%% Vcs-Hg (Mercurial),     directory : .hg
%% Vcs-Mtn (Monotone),     directory : _MTN
%% Vcs-Svn (Subversion)    directory : ../trunk !
%% @end
%%-------------------------------------------------------------------------
-spec get_vcs() -> atom().

get_vcs() -> try
                    case filelib:is_dir(".git") of
                        true  -> throw(git) ;
                        false -> false
                    end,
                    case filelib:is_dir(".hg") of
                        true  -> throw(hg) ;
                        false -> false
                    end,
                    case filelib:is_dir("_darcs") of
                        true  -> throw(darcs) ;
                        false -> false
                    end,
                    case filelib:is_dir("_MTN") of
                        true  -> throw(mtn) ;
                        false -> false
                    end,
                    case filelib:is_dir("CVS") of
                        true  -> throw(cvs) ;
                        false -> false
                    end,
                    case filelib:is_dir("../trunk") of
                        false -> throw(undefined) ;
                        true  -> case os:find_executable("bzr") of
                                      false -> case os:find_executable("svn") of
                                                    false -> throw(undefined) ; % strange...
                                                    _     -> throw(svn)
                                               end;
                                      _     -> case os:find_executable("svn") of
                                                    false -> throw(bzr) ;
                                                    _     -> throw(undefined) % cannot guess
                                               end
                                 end
                    end,
                    undefined
                catch
                    throw:VCS -> VCS
                end.

%%-------------------------------------------------------------------------
%% @doc Get VCS version / branch  TODO
%% @end
%%-------------------------------------------------------------------------
-spec get_vcs_version(atom()) -> string().

get_vcs_version(git)   -> string:strip(os:cmd("git log -1 --format='%H'"), right, $\n);
get_vcs_version(hg)    -> "TODO";
get_vcs_version(darcs) -> "TODO";
get_vcs_version(mtn)   -> "TODO";
get_vcs_version(cvs)   -> "TODO";
get_vcs_version(bzr)   -> "TODO";
get_vcs_version(svn)   -> "TODO";
get_vcs_version(_)     -> "".

%%-------------------------------------------------------------------------
%% @doc Get maintainer  TODO
%% @end
%%-------------------------------------------------------------------------
-spec get_maintainer(atom()) -> string().

get_maintainer(git)   -> string:strip(os:cmd("git config --get user.name"), right, $\n)++
                        "  <" ++ string:strip(os:cmd("git config --get user.email"), right, $\n)++ ">";
get_maintainer(hg)    -> "TODO";
get_maintainer(darcs) -> "TODO";
get_maintainer(mtn)   -> "TODO";
get_maintainer(cvs)   -> "TODO";
get_maintainer(bzr)   -> "TODO";
get_maintainer(svn)   -> "TODO";
get_maintainer(_)     -> "".

%%-------------------------------------------------------------------------
%% @doc Get VCS URL TODO
%% @end
%%-------------------------------------------------------------------------
-spec get_vcs_url(atom()) -> list().

get_vcs_url(git) -> vcs_git_translate(os:cmd("git config remote.origin.url"));
get_vcs_url(_) -> "".

%%-------------------------------------------------------------------------
%% @doc Translate URL from config to public URL 
%% @end
%%-------------------------------------------------------------------------
-spec vcs_git_translate(list()) -> list().

vcs_git_translate("https://" ++ A)   -> string:strip("https://"++A, right, $\n);
vcs_git_translate("git://" ++ A)     -> string:strip("https://"++A, right, $\n);
vcs_git_translate("git@" ++ A)       -> string:strip("https://"++A, right, $\n);
vcs_git_translate("file://" ++ _)    -> local;
vcs_git_translate(_)                 -> undefined.

%%-------------------------------------------------------------------------
%% @doc Get changelog file if any
%% return the name of the file found, if exists, otherwise 'undefined'. 
%% @end
%%-------------------------------------------------------------------------
-spec get_changelog() -> list() | undefined .

get_changelog() -> case filelib:wildcard("*") of
                           [] -> undefined ; % strange, but...
                           L  -> case lists:filter(fun(X) -> (string:to_lower(X) =:= "changelog") end, L) of
                                      []   -> undefined ;
                                      [C]  -> C ;
                                      _    -> undefined % Found more than one
                                 end
                      end.

%%-------------------------------------------------------------------------
%% @doc Get releasenotes file if any
%% return the name of the file found, if exists, otherwise 'undefined'. 
%% @end
%%-------------------------------------------------------------------------
-spec get_releasenotes() -> list() | undefined .

get_releasenotes() -> case filelib:wildcard("*") of
                        [] -> undefined ; % strange, but...
                        L  -> case lists:filter(fun(X) -> ((string:to_lower(X) =:= "releasenote") or 
                                                           (string:to_lower(X) =:= "releasenotes")) end, L) of
                                    []   -> undefined ;
                                    [R]  -> R ;
                                    _    -> undefined % Found more than one
                              end
                      end.

%%-------------------------------------------------------------------------
%% @doc Test if the project use a C driver
%% @end
%%-------------------------------------------------------------------------
-spec is_using_driver(list()) -> boolean().

is_using_driver(Dir) -> case filelib:is_dir(Dir) of
                            true  -> % Empty ?
                                     case filelib:wildcard("*") of
                                          [] -> false ;
                                          _  -> true
                                     end ;
                            false -> false
                        end.

%%-------------------------------------------------------------------------
%% @doc 
%% erlang:system_info({wordsize, internal}).
%%    Returns the size of Erlang term words in bytes as an integer, 
%%    i.e. on a 32-bit architecture 4 is returned, 
%%    and on a pure 64-bit architecture 8 is returned. 
%%    On a halfword 64-bit emulator, 4 is returned, as the Erlang terms are 
%%    stored using a virtual wordsize of half the system's wordsize.
%% {wordsize, external}
%%    Returns the true wordsize of the emulator, i.e. the size of a pointer, 
%%    in bytes as an integer. 
%%    On a pure 32-bit architecture 4 is returned, on both a halfword and 
%%    pure 64-bit architecture, 8 is returned.
%%
%%    internal | external |  architecture
%% ------------+----------+-----------------------------
%%       4     |    4     |  32-bit
%%       8     |    8     |  64-bit
%%       4     |    8     |  halfword 64-bit emulator
%% See also :
%% dpkg-architecture -L
%% @end
%%-------------------------------------------------------------------------
-spec get_word() -> integer().

get_word() -> N = erlang:system_info({wordsize, internal}) + 
                  erlang:system_info({wordsize, external}),
              case N of
                   8 -> 32 ;
                  16 -> 64 ;
                  12 -> 64 
              end.

%%-------------------------------------------------------------------------
%% @doc Get arch of native compiled modules, or local architecture otherwise
%% @end
%%-------------------------------------------------------------------------
-spec get_arch(boolean(), term()) -> atom().

get_arch(false, _) -> map_arch(erlang:system_info(hipe_architecture));

get_arch(true, EbinDir)  -> Beams = filelib:wildcard("*.beam", EbinDir),
                            [C] = lists:flatmap(fun(F) -> [get_arch_from_file(filename:join(EbinDir, F))] end, Beams),
                            C.

%%-------------------------------------------------------------------------
%% @doc Get arch of a native compiled module
%% @end
%%-------------------------------------------------------------------------
-spec get_arch_from_file(list()) -> atom().

get_arch_from_file(File) -> 
		  case filename:extension(File) of
			  ".erl" -> undefined ;
			  _      -> Bn = filename:rootname(File, ".beam"),
		                [{file,_}, {module,_}, {chunks,C}] = beam_lib:info(Bn),
		                Fun = fun({X, _, _}) -> case X of
		                                    "Atom" -> true ;
		                                    "Code" -> true ;
		                                    "StrT" -> true ;
		                                    "ImpT" -> true ;
		                                    "ExpT" -> true ;
		                                    "FunT" -> true ;
		                                    "LitT" -> true ;
		                                    "LocT" -> true ;
		                                    "Attr" -> true ;
		                                    "CInf" -> true ;
		                                    "Abst" -> true ;
		                                    "Line" -> true ;
		                                    _      -> false 
		                                end end,
		                case lists:dropwhile(Fun, C) of
		                     [] ->  get_arch(false, File) ;
		                     [{H, _, _}] -> case H of
		                                        "HS8P" -> ultrasparc ;
		                                        "HPPC" -> powerpc ;
		                                        "HP64" -> ppc64 ;
		                                        "HARM" -> arm ;
		                                        "HX86" -> x86 ;
		                                        "HA64" -> x86_64 ;
		                                        "HSV9" -> ultrasparc ;
		                                        "HW32" -> x86
		                                    end
		                end
			end.

%%-------------------------------------------------------------------------
%% @doc Map internal architecture atom to something else if needed
%% @end
%%-------------------------------------------------------------------------
-spec map_arch(atom()) -> atom().

map_arch(X) -> X.


%%-------------------------------------------------------------------------
%% @doc Check if something is compiled native
%% @end
%%-------------------------------------------------------------------------
-spec is_native(list()) -> boolean().

is_native(EbinDir) ->  Beams = filelib:wildcard("*.beam", EbinDir),
                       Check = lists:flatmap(fun(F) -> [is_native_from_file(filename:join(EbinDir, F))] end, Beams),
                       lists:any(fun(X) -> (X =:= true) end, Check).

%%-------------------------------------------------------------------------
%% @doc Check if a beam file is compiled native
%% See also : code:is_module_native(module). 
%% @end
%%-------------------------------------------------------------------------
-spec is_native_from_file(list()) -> boolean().

is_native_from_file(File) ->   
		case filename:extension(File) of
			".erl" -> undefined ;
			_      -> Bn = filename:rootname(File, ".beam"),
                      case filelib:is_regular(File) of
                            true -> {ok,{_,[{compile_info, L}]}} = beam_lib:chunks(Bn, [compile_info]),
                                    {options, O} = lists:keyfind(options, 1, L),
                                    lists:member(native, O);
                            false -> undefined
                      end
		end.

%%-------------------------------------------------------------------------
%% @doc Get compile module version
%% @end
%%-------------------------------------------------------------------------
-spec get_compile_version(list()) -> list().

get_compile_version(File) ->
		case filename:extension(File) of
			".erl" -> undefined ;
			_      -> Bn = filename:rootname(File, ".beam"),
                      case filelib:is_regular(File) of
                            true -> {ok,{_,[{compile_info, L}]}} = beam_lib:chunks(Bn, [compile_info]),
                                    {version, E} = lists:keyfind(version, 1, L),
                                    E;
                            false -> undefined 
                      end
		end.

%%-------------------------------------------------------------------------
%% @doc Get application name, version, desc from .app file in ebin/ directory
%% @end
%%-------------------------------------------------------------------------
-spec get_app_infos(list()) -> tuple().

get_app_infos(File) ->  {ok,[{application, App, L}]} = file:consult(File),
                        VSN  = case lists:keyfind(vsn, 1, L) of
                                    {vsn, V} -> V ;
                                    _        -> undefined
                               end,
                        Desc = case lists:keyfind(description, 1, L) of
                                    {description, D} -> D ;
                                    _                -> undefined
                               end,
                        {App, VSN, Desc}.


%%-------------------------------------------------------------------------
%% @doc Get application creation date
%% @end
%%-------------------------------------------------------------------------
-spec get_date(list()) -> list().

get_date(File) ->  
		case filename:extension(File) of
			".erl" -> undefined ;
			_      -> Bn = filename:rootname(File, ".beam"),
                   	  case filelib:is_regular(File) of
                        true -> {ok,{_,[{compile_info, L}]}} = beam_lib:chunks(Bn, [compile_info]),
                                {time, T} = lists:keyfind(time, 1, L),
                                T;
                        false -> undefined
                      end
		end.

%%-------------------------------------------------------------------------
%% @doc Get application author
%% @end
%% beam_lib:chunks("/home/eric/git/swab/ebin/swab", [attributes]).
%% {ok,{swab,[{attributes,[{author,"Eric Pailleau <swab@crownedgrouse.com>"},
%%                         {vsn,[29884121306770099633619336282407733599]}]}]}}
%%-------------------------------------------------------------------------
-spec get_author(list()) -> list() | undefined.

get_author(File) ->   
		case filename:extension(File) of
			".erl" -> undefined ;
			_      -> Bn = filename:rootname(File, ".beam"),
                   	  case filelib:is_regular(File) of
                        true -> {ok,{_,[{attributes, L}]}} = beam_lib:chunks(Bn, [attributes]),
                                A = case lists:keyfind(author, 1, L) of
                                            {author, B} -> B ;
                                            _           -> undefined
                                    end,
                                A;
                        false -> undefined
                   	  end
		end.

%%-------------------------------------------------------------------------
%% @doc Get {min, recommanded, max} Erlang version from erts version
%% Look into https://github.com/erlang/otp/blob/maint/lib/compiler/vsn.mk
%%-------------------------------------------------------------------------
-spec get_erlang_version(list()) -> {list(), list(), list()} | undefined.

get_erlang_version("6.0.2")     -> {"18.2", "18.2", "18.2"};
get_erlang_version("6.0.1")     -> {"18.1", "18.1", "18.1"};
get_erlang_version("6.0")       -> {"18.0-rc2", "18.0-rc2", "18.0-rc2"};
get_erlang_version("5.0.4")     -> {"17.5", "17.5.3", "17.5.3"};
get_erlang_version("5.0.3")     -> {"17.4", "17.4.1", "18.0-rc1"};
get_erlang_version("5.0.2")     -> {"17.3", "17.3.4", "17.3.4"};
get_erlang_version("5.0.1")     -> {"17.1", "17.2.2", "17.2.2"};
get_erlang_version("5.0")       -> {"17.0", "17.0.2", "17.0.2"};
get_erlang_version("4.9.4")     -> {"R16B03", "R16B03-1", "17.0-rc2"};
get_erlang_version("4.9.3")     -> {"R16B02", "R16B02", "R16B02"};
get_erlang_version("4.9.2")     -> {"R16B01", "R16B01", "R16B01"};
get_erlang_version("4.9.1")     -> {"R16B", "R16B", "R16B"};
get_erlang_version("4.8.2")     -> {"R15B02", "R15B03-1", "R15B03-1"};
get_erlang_version("4.8.1")     -> {"R15B01", "R15B01", "R15B01"};
get_erlang_version("4.8")       -> {"R15B", "R15B", "R15B"};
get_erlang_version("4.7.5.pre") -> {"R15A", "R15A", "R15A"};
get_erlang_version("4.7.5")     -> {"R14B04", "R14B04", "R14B04"};
get_erlang_version("4.7.4")     -> {"R14B03", "R14B03", "R14B03"};
get_erlang_version("4.7.3")     -> {"R14B02", "R14B02", "R14B02"};
get_erlang_version("4.7.2")     -> {"R14B01", "R14B01", "R14B01"};
get_erlang_version("4.7.1")     -> {"R14B", "R14B", "R14B"};
get_erlang_version("4.7")       -> {"R14B", "R14B", "R14B"};
get_erlang_version("4.6.5")     -> {"R13B04", "R13B04", "R13B04"};
get_erlang_version("4.6.4")     -> {"R13B03", "R13B03", "R13B03"};
get_erlang_version(_)           -> undefined.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Guessing the minimal/maximal Erlang release usable with a .beam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%-------------------------------------------------------------------------
%% @doc Analyze compatibility of all beam in directory
%%-------------------------------------------------------------------------
-spec get_erlang_compat(list()) -> {list(), list(), list(), list()}.

get_erlang_compat(Dir) -> Joker = case os:getenv("GEAS_USE_SRC") of
							   			false -> "ebin/*.beam" ;
							   			"0"   -> "ebin/*.beam" ;
							   			"1"   -> "src/**/*.erl"
				   		  		  end,
						  Beams = filelib:wildcard(Joker, Dir),
                          X = lists:usort(lists:flatmap(fun(F) -> [get_erlang_compat_beam(filename:join(Dir,F))] end, Beams)),
                          {MinList, MaxList} = lists:unzip(X),
                          % Get the highest version of Min releases of all beam
                          MinR = highest_version(MinList),
                          % Get the lowest version of Max releases of all beam
                          MaxR = lowest_version(MaxList),
                          {?GEAS_MIN_REL , MinR, MaxR, ?GEAS_MAX_REL}.

%%-------------------------------------------------------------------------
%% @doc Analyze compatibility of a beam from file
%%-------------------------------------------------------------------------
-spec get_erlang_compat_file(list()) -> {list(), list(), list(), list()}.

get_erlang_compat_file(File) -> X = lists:usort(lists:flatmap(fun(F) -> [get_erlang_compat_beam(F)] end, [File])),
                                {MinList, MaxList} = lists:unzip(X),
                                % Get the highest version of Min releases of all beam
                                MinR = highest_version(MinList),
                                % Get the lowest version of Max releases of all beam
                                MaxR = lowest_version(MaxList),
                                {?GEAS_MIN_REL , MinR, MaxR, ?GEAS_MAX_REL}.

%%-------------------------------------------------------------------------
%% @doc Analyze compatibility of a beam file
%%-------------------------------------------------------------------------
-spec get_erlang_compat_beam(list()) -> {list(), list()}.

get_erlang_compat_beam(File) -> % Extract all Erlang MFA in Abstract code
                                Abs1 = get_abstract(File),                         
                                X = lists:usort(lists:flatten(lists:flatmap(fun(A) -> [get_remote_call(A)] end, Abs1))),
                                %io:format("~p~n", [X)])
                                % Get the min and max release for each MFA
                                % Get the min release compatible
                                Min = lists:flatmap(fun(A) -> [{rel_min(A), A}] end, X),
                                {MinRelss, _} = lists:unzip(Min),
                                MinRels = lists:filter(fun(XX) -> case XX of undefined -> false; [] -> false;_ -> true end end, lists:usort(MinRelss)),
                                % Get the max release compatible
                                Max = lists:flatmap(fun(A) -> [{rel_max(A), A}] end, X),
                                {MaxRelss, _} = lists:unzip(Max),
                                MaxRels = lists:filter(fun(XX) -> case XX of undefined -> false; [] -> false; _ -> true end end, lists:usort(MaxRelss)),
                                {lowest_version(MinRels), highest_version(MaxRels)}. 

%%-------------------------------------------------------------------------
%% @doc Extract remote call of external functions in abstract code
%%-------------------------------------------------------------------------
-spec get_remote_call(tuple()) -> list().

get_remote_call({call,_, {remote,_,{atom, _,M},{atom, _, F}}, Args}) 
                when is_list(Args)-> [{M, F, length(Args)}, lists:flatmap(fun(X) -> get_remote_call(X) end, Args)] ;
get_remote_call({_, _, _, L1, L2, L3}) when is_list(L1),
                                            is_list(L2),
                                            is_list(L3) -> [lists:flatmap(fun(X) -> get_remote_call(X) end, L1),
                                                            lists:flatmap(fun(X) -> get_remote_call(X) end, L2),
                                                            lists:flatmap(fun(X) -> get_remote_call(X) end, L3)]
                                                                 ;
get_remote_call({_, _, _, _, L}) when is_list(L) -> lists:flatmap(fun(X) -> get_remote_call(X) end, L) ;
get_remote_call({_, _, _, _, _}) -> [] ;
get_remote_call({_, _, _, L})   when is_list(L) -> lists:flatmap(fun(X) -> get_remote_call(X) end, L) ;
get_remote_call({_, _, _, T})   when is_tuple(T) -> get_remote_call(T) ;
get_remote_call({_, _, _, _}) -> [] ; 
get_remote_call({_, _, L}) when is_list(L) -> lists:flatmap(fun(X) -> get_remote_call(X) end, L) ;
get_remote_call({_, _, _}) -> [] ;
get_remote_call({_, _}) -> [] ;
get_remote_call(_I) when is_integer(_I) -> [];
get_remote_call(_A) when is_atom(_A) -> [];
get_remote_call(_Z) -> %io:format("Missed : ~p~n", [_Z]), 
                       [].

%%-------------------------------------------------------------------------
%% @doc  Give the lowest version from a list of versions
%%-------------------------------------------------------------------------
-spec lowest_version(list()) -> list().

lowest_version([]) -> [] ;
lowest_version(L) when is_list(L),
                       (length(L) == 1) -> [V] = L, V ;
lowest_version(L) when is_list(L),
                       (length(L) > 1)  -> [V | _] = lists:usort(fun(A, B) -> 
                                                                     X = lowest_version(A, B),
                                                                     case (X == A) of
                                                                        true -> true ;
                                                                        _    -> false
                                                                     end                          
                                                                 end, L), V.

%%-------------------------------------------------------------------------
%% @doc Give the lowest version from two versions
%%-------------------------------------------------------------------------
-spec lowest_version(list(), list()) -> list().

lowest_version([], B) -> B;
lowest_version(A, []) -> A;
lowest_version(A, B) when A =/= B  -> AA = versionize(A),
                                      BB = versionize(B),
                                      [Vmin, _Vmax] = lists:usort([AA,BB]),
                                      Vmin;
lowest_version(A, _B) -> A.

%%-------------------------------------------------------------------------
%% @doc Give the highest version from a list of versions
%%-------------------------------------------------------------------------
-spec highest_version(list()) -> list().

highest_version([]) -> [] ;
highest_version(L) when is_list(L),
                       (length(L) == 1) -> [V] = L, V ;
highest_version(L) when is_list(L),
                       (length(L) > 1)  -> [V | _] = lists:usort(fun(A, B) -> 
                                                                     X = highest_version(A, B),
                                                                     case (X == A) of
                                                                        true -> true ;
                                                                        _    -> false
                                                                     end                          
                                                                 end, L), V.

%%-------------------------------------------------------------------------
%% @doc Give the highest version from two versions
%%-------------------------------------------------------------------------
-spec highest_version(list(), list()) -> list().

highest_version([], B) -> B;
highest_version(A, []) -> A;
highest_version(A, B) when A =/= B -> AA = versionize(A),
                                      BB = versionize(B),
                                      [_Vmin, Vmax] = lists:usort([AA,BB]),                                      
                                      Vmax;
highest_version(A, _B) -> A.

%%-------------------------------------------------------------------------
%% @doc Translate old release name into new name
%%      Exemple R16B03 into 16.2.3
%%-------------------------------------------------------------------------
-spec versionize(list()) -> list().

versionize([]) -> [];
versionize(V)  -> 
                 [Pref | Tail] = V,
                 case Pref of
                     $R -> Split = re:split(Tail,"([AB])",[{return,list}]),
                           New = lists:map(fun(X) -> XX = case X of 
                                                                "A" -> "1" ;
                                                                "B" -> "2" ;
                                                                X   -> X 
                                                           end,
                                                           case string:to_integer(XX) of
                                                                {error, no_integer} -> [] ;
                                                                {error, not_a_list} -> [] ;
                                                                {L, []} -> [integer_to_list(L)] ;
                                                                {L, R} when is_integer(L),
                                                                            is_list(R) -> [integer_to_list(L) ++ R] ;
                                                                _                   -> []
                                                           end
                                            end, Split),
                            VV = lists:flatten(string:join(New, ".")),
                                 VV;
                     _   -> V
                 end.
%%-------------------------------------------------------------------------
%% @doc Give the offending modules/functions that reduce release window
%%-------------------------------------------------------------------------
offending(File) -> % check it is a file or exit
                   case filelib:is_regular(File) of
                        false -> {error, invalid_argument} ;
                        true  -> % Apply geas:what on the beam, bring lowest and highest if necessary
                                 {ok, L } = geas:what(File),
                                 {compat, Compat} = lists:keyfind(compat, 1, L),
                                 {A, B, C, D} = Compat,
                                 MinOff = case A =/= B of
                                                true -> get_min_offending(B, File) ;
                                                false -> [] 
                                          end, 
                                 MaxOff = case C =/= D of
                                                true -> get_max_offending(C, File) ;
                                                false -> [] 
                                          end, 
                                 {ok, {MinOff, MaxOff}}
                   end.
%%-------------------------------------------------------------------------
%% @doc Give the offending min modules/functions that reduce release window
%%-------------------------------------------------------------------------
get_min_offending(Rel, File) -> Abs = get_abstract(File),
								X = lists:usort(lists:flatten(lists:flatmap(fun(A) -> [get_remote_call(A)] end, Abs))),
							    % From list get the release of offending functions
							    R = lists:flatmap(fun(F) -> [{rel_min(F), F}] end , X),
							    % Extract only the release we search
							    R1 = lists:filter(fun({Relx, _A}) -> (Rel == Relx) end, R),
							    %% Extract the function
							    [{Rel, lists:flatmap(fun({_, FF}) -> [FF] end, R1)}].

%%-------------------------------------------------------------------------
%% @doc Give the offending max modules/functions that reduce release window
%%-------------------------------------------------------------------------
get_max_offending(Rel, File) ->  Abs = get_abstract(File),
								 X = lists:usort(lists:flatten(lists:flatmap(fun(A) -> [get_remote_call(A)] end, Abs))),
					         	 % From list get the release of offending functions
					             R = lists:flatmap(fun(F) -> [{rel_max(F), F}] end , X),
					             % Extract only the release we search
					             R1 = lists:filter(fun({Relx, _A}) -> (Rel == Relx) end, R),
					             %% Extract the function
					             [{Rel, lists:flatmap(fun({_, FF}) -> [FF] end, R1)}]. 
  
%%-------------------------------------------------------------------------
%% @doc Compat output on stdout, mainly for erlang.mk plugin
%%-------------------------------------------------------------------------

compat(RootDir) -> compat(RootDir, print).

compat(RootDir, deps) -> {_, _, Deps} = compat(RootDir, term),
						 Deps;

compat(RootDir, global) -> {{_, MinGlob, MaxGlob, _}, _, _} = compat(RootDir, term),
						   {?GEAS_MIN_REL, MinGlob, MaxGlob, ?GEAS_MAX_REL};

compat(RootDir, term) ->
					% Get all .beam (or .erl) files recursively
					Ext = ext_to_search(),
                    PP = filelib:fold_files(filename:join(RootDir,"deps"), Ext, true, 
                            fun(X, Y) -> P = filename:dirname(filename:dirname(X)),
										 case filename:basename(P) of
											  "geas" -> Y ; % Exclude geas from results
											  "src"  -> case lists:member(filename:dirname(P), Y) of
                                              				true  -> Y ;
                                              				false -> Y ++ [filename:dirname(P)]
														end;
											  _      -> case lists:member(P, Y) of
                                              				true  -> Y ;
                                              				false -> Y ++ [P]
														end
                                         end
                            end, []),
                    % Get all upper project
                    Ps = lists:usort(PP),
                    Global = Ps ++ [RootDir],
                    D = lists:flatmap(fun(X) -> 
											 {ok, I} = info(X),
                                             Compat = lists:keyfind(compat, 1, I),
                                             {compat,{MinDb, Min, Max, MaxDb}} = Compat,
                                             N = lists:keyfind(native, 1, I),
                                             {native, Native} = N,
                                             A = lists:keyfind(arch, 1, I),
                                             {arch, Arch} = A,
                                             ArchString = case Native  of
                                                               true -> atom_to_list(Arch) ;
                                                               false -> "" 
                                                          end,
                                             Left  = case (MinDb =:= Min) of
                                                            true  -> "" ;
                                                            false -> Min
                                                     end,
                                             Right = case (MaxDb =:= Max) of
                                                            true  -> "" ;
                                                            false -> Max
                                                     end,
                                             [{Left , ArchString, Right, filename:basename(X)}]
                                       end, Global),
                    % Get global info
					MinList = lists:usort([?GEAS_MIN_REL] ++ lists:flatmap(fun({X, _, _, _}) -> [X] end, D)),
                    MinGlob = highest_version(MinList) ,
					ArchList = lists:usort(lists:flatmap(fun({_, X, _, _}) -> [X] end, D)),
                    ArchGlob = tl(ArchList), % Assuming only one arch localy !
					MaxList = lists:usort([?GEAS_MAX_REL] ++ lists:flatmap(fun({_, _, X, _}) -> [X] end, D)),
                    MaxGlob = lowest_version(MaxList) ,
                    {{?GEAS_MIN_REL, MinGlob, MaxGlob, ?GEAS_MAX_REL}, ArchGlob, D};

compat(RootDir, print) -> 
					{{_, MinGlob, MaxGlob, _}, ArchGlob, D} = compat(RootDir, term),
                    % Display header
                    io:format("   ~-10s            ~-10s ~-20s~n",[?GEAS_MIN_REL , ?GEAS_MAX_REL, "Geas database"]),
                    io:format("~s~s~n",["---Min--------Arch-------Max--",string:copies("-",50)]),
                    lists:foreach(fun({LD, AD, RD, FD}) -> io:format("   ~-10s ~-10s ~-10s ~-20s ~n",[LD, AD, RD, FD]) end, D),
                    io:format("~80s~n",[string:copies("-",80)]),
                    io:format("   ~-10s ~-10s ~-10s ~-20s ~n",[MinGlob , ArchGlob, MaxGlob, "Global project"]),
                    ok.

%%-------------------------------------------------------------------------
%% @doc Offending output on stdout, mainly for erlang.mk plugin
%%-------------------------------------------------------------------------

guilty(RootDir) -> Ext = ext_to_search(),
				   DirS = dir_to_search(),
				   Bs1 = filelib:fold_files(filename:join(RootDir, "deps"), Ext, true, 
                            				fun(X, Y) -> Y ++ [X] end, []),
				   Bs2 = filelib:fold_files(filename:join(RootDir, DirS), Ext, true, 
                            				fun(X, Y) -> Y ++ [X] end, []),
				   Bs = Bs1 ++ Bs2,
				   % Check Offendings for each beam / erl
				   All = lists:flatmap(fun(X) -> Off = offending(X),
										   case Off of
												{ok, []}          -> [] ;
												{ok, {[],[]}}     -> [] ;
												{ok, {[{[],[]}],[]}} -> [] ;
												{ok, {[],[{[],[]}]}} -> [] ;
												{ok,{[{[],[]}],[{[],[]}]}} -> [] ;
												{ok,{Left,Right}} -> [{X, Left, Right}] ;
												_E                -> []
										   end
								       end, Bs),
				   lists:foreach(fun({_F, L, R}) -> 
								   io:format("~n~ts", [_F]) ,
								   case L of
										[{Min, MinList}] -> io:format("~n~-10ts", [Min]),
															LL = lists:flatmap(fun({M, F, A}) -> 
																				[atom_to_list(M) ++ ":" ++ 
																				 atom_to_list(F) ++ "/" ++ 
																				 integer_to_list(A)] end, MinList),
															io:format("~ts~n", [string:join(LL, ", ")]) ;
										_  -> ok
								   end,
								   case R of
										[{Max, MaxList}] -> io:format("~n~-10ts", [Max]),
															RR = lists:flatmap(fun({M, F, A}) -> 
																				[atom_to_list(M) ++ ":" ++ 
																				 atom_to_list(F) ++ "/" ++ 
																				 integer_to_list(A)] end, MaxList),
															io:format("~ts~n", [string:join(RR, ", ")]) ;
										_  -> ok
								   end
														
								 end, lists:usort(All)) .

%%-------------------------------------------------------------------------
%% @doc Get abstract file either from beam or src file
%%-------------------------------------------------------------------------
get_abstract(File) -> 
					  case filename:extension(File) of
						  ".beam" -> get_abstract(File, beam) ;
						  ".erl"  -> get_abstract(File, src) ;
						  _       -> []
					  end.

get_abstract(File, beam) -> %io:format("beam ~p~n",[File]), 
							case beam_lib:chunks(File,[abstract_code]) of
								{ok,{_,[{abstract_code,{_, Abs}}]}} -> Abs;
								{ok,{_,[{abstract_code,no_abstract_code}]}} -> 
										% Try on source file as fallback
									    SrcFile = get_src_from_beam(File),
										case filelib:is_regular(SrcFile) of
									    	 true  -> get_abstract(SrcFile, src) ;
											 false -> []
										end
						     end;


get_abstract(File, src) ->	%io:format("src  ~p~n",[File]), 
							% IncDir = filename:join(filename:dirname(filename:dirname(File)),"include"),
							% Add non conventional include dir for sub-directories in src/
							IncDir = get_upper_dir(filename:dirname(File), "include"),
							SrcDir = get_upper_dir(filename:dirname(File), "src"),
							%io:format("inc ~p~nsrc ~p~n",[IncDir, SrcDir]),
							% DO NOT USE : epp:parse_file/2, because starting "R16B03-1" 
							% Geas need to work on the maximal release window
							{ok , Form} = epp:parse_file(File, [{includes,[filename:dirname(File), IncDir, SrcDir]}], []),
							Form. 


get_src_from_beam(File) -> 	UpperDir = filename:dirname(filename:dirname(File)),
							SrcDir = filename:join(UpperDir, "src"),
							Basename = filename:rootname(filename:basename(File)),
							filename:join([SrcDir, Basename, ".erl"]).

%%-------------------------------------------------------------------------
%% @doc Get file extension to search depending option environment variable
%%-------------------------------------------------------------------------

ext_to_search() -> case os:getenv("GEAS_USE_SRC") of
							   false -> ".beam$" ;
							   "0"   -> ".beam$" ;
							   "1"   -> ".erl$"
				   end.

%%-------------------------------------------------------------------------
%% @doc Get directory to search depending mode
%%-------------------------------------------------------------------------
dir_to_search() -> case os:getenv("GEAS_USE_SRC") of
							   false -> "ebin" ;
							   "0"   -> "ebin" ;
							   "1"   -> "src"
				   end.

%%-------------------------------------------------------------------------
%% @doc Get upper/parallel directory matching a needle
%%-------------------------------------------------------------------------
get_upper_dir("/", _) -> "" ;
get_upper_dir(Dir, Needle) -> case filename:basename(Dir) of
									Needle -> Dir ;
									_      -> case filelib:is_dir(filename:join(Dir, Needle)) of
												false -> get_upper_dir(filename:dirname(Dir), Needle) ;
												true  -> filename:join(Dir, Needle)
											  end
							  end.


 
%%-------------------------------------------------------------------------
%% @doc rebar plugin call function
%%-------------------------------------------------------------------------

geas(_, _ ) -> {ok, Dir} = file:get_cwd(),
			   compat(Dir),
			   guilty(Dir).

