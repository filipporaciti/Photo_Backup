import os


dirpath = input('Insert path to directory where images are saved: ')
files = os.listdir(dirpath)

falied = []

for i, file in enumerate(files):

	print(str(i+1) + '/' + str(len(files)) + " --> " + file)

	try:
		data = file.split('_')
		date = []
		date.append(data[0].split('-')[1])
		date.append(data[0].split('-')[2])
		date.append(data[0].split('-')[0])
		date = '/'.join(date)
		time = ':'.join(data[1].split('-'))

		datetime = date + " " + time

		command = 'SetFile -d "' + datetime + '" -m "' + datetime + '" ' + dirpath + file
		# print(command)
		os.system(command)
	except:
		falied.append(file)

print('Falied: ')
print(falied)
