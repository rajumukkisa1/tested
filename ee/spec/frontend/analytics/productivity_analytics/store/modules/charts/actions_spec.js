import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'helpers/test_constants';
import * as actions from 'ee/analytics/productivity_analytics/store/modules/charts/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/charts/mutation_types';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/charts/state';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import { mockHistogramData } from '../../../mock_data';

describe('Productivity analytics chart actions', () => {
  let mockedContext;
  let mockedState;
  let mock;

  const chartKey = chartKeys.main;
  const globalParams = {
    group_id: 'gitlab-org',
    project_id: 'gitlab-org/gitlab-test',
  };

  beforeEach(() => {
    mockedContext = {
      dispatch() {},
      rootState: {
        endpoint: `${TEST_HOST}/analytics/productivity_analytics.json`,
      },
      getters: {
        getFilterParams: () => globalParams,
      },
      state: getInitialState(),
    };

    // testAction looks for rootGetters in state,
    // so they need to be concatenated here.
    mockedState = {
      ...mockedContext.state,
      ...mockedContext.getters,
      ...mockedContext.rootState,
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchChartData', () => {
    describe('when chart is enabled', () => {
      describe('success', () => {
        beforeEach(() => {
          mock.onGet(mockedState.endpoint).replyOnce(200, mockHistogramData);
        });

        it('calls API with params', () => {
          jest.spyOn(axios, 'get');

          actions.fetchChartData(mockedContext, chartKey);

          expect(axios.get).toHaveBeenCalledWith(mockedState.endpoint, { params: globalParams });
        });

        it('dispatches success with received data', done =>
          testAction(
            actions.fetchChartData,
            chartKey,
            mockedState,
            [],
            [
              { type: 'requestChartData', payload: chartKey },
              {
                type: 'receiveChartDataSuccess',
                payload: expect.objectContaining({ chartKey, data: mockHistogramData }),
              },
            ],
            done,
          ));
      });

      describe('error', () => {
        beforeEach(() => {
          mock.onGet(mockedState.endpoint).replyOnce(500);
        });

        it('dispatches error', done => {
          testAction(
            actions.fetchChartData,
            chartKey,
            mockedState,
            [],
            [
              {
                type: 'requestChartData',
                payload: chartKey,
              },
              {
                type: 'receiveChartDataError',
                payload: {
                  chartKey,
                  error: new Error('Request failed with status code 500'),
                },
              },
            ],
            done,
          );
        });
      });
    });
  });

  describe('requestChartData', () => {
    it('should commit the request mutation', done => {
      testAction(
        actions.requestChartData,
        chartKey,
        mockedContext.state,
        [{ type: types.REQUEST_CHART_DATA, payload: chartKey }],
        [],
        done,
      );
    });

    describe('when chart is disabled', () => {
      const disabledChartKey = chartKeys.scatterplot;
      beforeEach(() => {
        mock.onGet(mockedState.endpoint).replyOnce(200);
        mockedState.charts[disabledChartKey].enabled = false;
      });

      it('does not dispatch the requestChartData action', done => {
        testAction(actions.fetchChartData, disabledChartKey, mockedState, [], [], done);
      });

      it('does not call the API', () => {
        actions.fetchChartData(mockedContext, disabledChartKey);
        jest.spyOn(axios, 'get');
        expect(axios.get).not.toHaveBeenCalled();
      });
    });
  });

  describe('receiveChartDataSuccess', () => {
    it('should commit received data', done => {
      testAction(
        actions.receiveChartDataSuccess,
        { chartKey, data: mockHistogramData },
        mockedContext.state,
        [
          {
            type: types.RECEIVE_CHART_DATA_SUCCESS,
            payload: { chartKey, data: mockHistogramData },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveChartDataError', () => {
    it('should commit error', done => {
      const error = { response: { status: 500 } };
      testAction(
        actions.receiveChartDataError,
        { chartKey, error },
        mockedContext.state,
        [
          {
            type: types.RECEIVE_CHART_DATA_ERROR,
            payload: {
              chartKey,
              status: 500,
            },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchSecondaryChartData', () => {
    it('dispatches fetchChartData for all chart types except for the main chart', done => {
      testAction(
        actions.fetchSecondaryChartData,
        null,
        mockedContext.state,
        [],
        [
          { type: 'fetchChartData', payload: chartKeys.timeBasedHistogram },
          { type: 'fetchChartData', payload: chartKeys.commitBasedHistogram },
          { type: 'fetchChartData', payload: chartKeys.scatterplot },
        ],
        done,
      );
    });
  });

  describe('setMetricType', () => {
    const metricType = 'time_to_merge';

    it('should commit metricType', done => {
      testAction(
        actions.setMetricType,
        { chartKey, metricType },
        mockedContext.state,
        [{ type: types.SET_METRIC_TYPE, payload: { chartKey, metricType } }],
        [{ type: 'fetchChartData', payload: chartKey }],
        done,
      );
    });
  });

  describe('updateSelectedItems', () => {
    describe('when skipReload is false (by default)', () => {
      const item = 5;
      it('should commit selected chart item and dispatch fetchSecondaryChartData and setPage', done => {
        testAction(
          actions.updateSelectedItems,
          { chartKey, item },
          mockedContext.state,
          [{ type: types.UPDATE_SELECTED_CHART_ITEMS, payload: { chartKey, item } }],
          [{ type: 'fetchSecondaryChartData' }, { type: 'table/setPage', payload: 0 }],
          done,
        );
      });
    });

    describe('when skipReload is true', () => {
      it('should commit selected chart and it should not dispatch any further actions', done => {
        testAction(
          actions.updateSelectedItems,
          { chartKey, item: null, skipReload: true },
          mockedContext.state,
          [
            {
              type: types.UPDATE_SELECTED_CHART_ITEMS,
              payload: { chartKey: chartKeys.main, item: null },
            },
          ],
          [],
          done,
        );
      });
    });
  });

  describe('setChartEnabled', () => {
    it('should commit enabled state', done => {
      testAction(
        actions.setChartEnabled,
        { chartKey: chartKeys.scatterplot, isEnabled: false },
        mockedContext.state,
        [
          {
            type: types.SET_CHART_ENABLED,
            payload: { chartKey: chartKeys.scatterplot, isEnabled: false },
          },
        ],
        [],
        done,
      );
    });
  });
});