import TerraformState from './fragments/state.fragment.graphql';

export default {
  TerraformState: {
    _showDetails: (state) => {
      // eslint-disable-next-line no-underscore-dangle
      return state._showDetails || false;
    },
    errorMessages: (state) => {
      return state.errorMessages || [];
    },
    loadingActions: (state) => {
      return state.loadingActions || false;
    },
  },
  Mutation: {
    addDataToTerraformState: (_, { terraformState }, { client }) => {
      const fragmentData = {
        id: terraformState.id,
        fragment: TerraformState,
        // eslint-disable-next-line @gitlab/require-i18n-strings
        fragmentName: 'State',
      };

      const previousTerraformState = client.readFragment(fragmentData);

      if (previousTerraformState) {
        client.writeFragment({
          ...fragmentData,
          data: {
            ...previousTerraformState,
            // eslint-disable-next-line no-underscore-dangle
            _showDetails: terraformState._showDetails,
            errorMessages: terraformState.errorMessages,
            loadingActions: terraformState.loadingActions,
          },
        });
      }
    },
  },
};
