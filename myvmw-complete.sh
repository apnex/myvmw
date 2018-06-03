_myvmw()
{
	local cur prev list

	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	list='VMware\ vSphere test1 test2'
	#list=`myvmw list`
	list=("moo", "Baa")

	#if [[ ${cur_word} == get ]]; then
	#	COMPREPLY=( $(compgen -W "${list}" -- ${cur}) )
		#COMPREPLY=( $(compgen -f keys -- ${cur}) )
	COMPREPLY=( $(./return.pl) )
	#else
	#	COMPREPLY=()
	#fi
	#return 0
}
complete -F _myvmw myvmw
