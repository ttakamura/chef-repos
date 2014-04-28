include_recipe 'apt'
include_recipe 'build-essential'

package 'git'
package 'zsh'
package 'emacs'
package 'tmux'
package 'mosh'
package 'python-pip'

bash 'Setup aws cli' do
  code   'pip install awscli'
  not_if 'which aws'
end
