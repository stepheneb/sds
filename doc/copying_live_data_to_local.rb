# execute this in Ruby while connected to CC network
# replace 'sds_real_data' with the name of the local database you want created

sdstables = `mysqlshow -u rails --password='****' -h railsdb.concord.org rails 'sds_%'`.scan(/sds_\S*/)[1..-1].join(' ')
`mysqldump -u rails --password='****' -h railsdb.concord.org rails #{sdstables} | mysql -u root --password='****' -h localhost -C sds_real_data`

# do this when remote, replace 'username' with your ssh username at CC
# I can't remember how this works -- needs testing and documenting)

ssh -L 8888:railsdb.concord.org:3306 username@railsdb.concord.org
mysqlshow -u rails --password='****' -h 127.0.0.1 -P 8888 rails
