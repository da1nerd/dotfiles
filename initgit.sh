WORKSPACE=$HOME/git

if [ -e $WORKSPACE ]; then
	echo "creating git workspace"
	mkdir -p $WORKSPACE
fi

echo "fetching github projects"
mkdir -p ${WORKSPACE}/door43
git clone git@github.com:neutrinog/ts-android.git ${WORKSPACE}/door43/ts-android
cd ts-desktop
git remote add upstream git@github.com:unfoldingWord-dev/ts-android.git
cd ..
git clone git@github.com:neutrinog/ts-desktop.git ${WORKSPACE}/door43/ts-desktop
cd ts-desktop
git remote add upstream git@github.com:unfoldingWord-dev/ts-desktop.git
cd ..
git clone git@github.com:neutrinog/node-gogs-client.git ${WORKSPACE}/door43/node-gogs-client
git clone git@github.com:neutrinog/android-gogs-client.git ${WORKSPACE}/door43/android-gogs-client

echo "fetching private projects"
git clone git@neutrino.graphics:atomic ${WORKSPACE}/atomic
git clone git@neutrino.graphics:atomic_ext ${WORKSPACE}/atomic_ext
git clone git@neutrino.graphics:gitolite-admin.git ${WORKSPACE}/neutrino-gitolite-admin
git clone git@neutrino.graphics:prayersheet_android.git ${WORKSPACE}/prayersheet

