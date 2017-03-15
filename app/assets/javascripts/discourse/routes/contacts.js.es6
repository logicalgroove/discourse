import { ajax } from 'discourse/lib/ajax';
export default Discourse.Route.extend({
    model() {
        return ajax("/contacts.json").then(result => {
            return result
        });
    },

    titleToken() {
        return I18n.t('contacts');
    },

    actions: {
        didTransition() {
            this.controllerFor("application").set("showFooter", true);
            return true;
        }
    }
});
