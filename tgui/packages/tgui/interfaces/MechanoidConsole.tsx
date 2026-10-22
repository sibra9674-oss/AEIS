import {
  Box,
  Button,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Mechanoid = {
  name: string;
  ref: string;
  bandwidth: number;
  health: number;
  area: string;
  piloted: boolean;
  master: string | null;
};

type ConsoleData = {
  bandwidth_used: number;
  bandwidth_max: number;
  mechanoids: Mechanoid[];
};

export const MechanoidConsole = (props) => {
  const { act, data } = useBackend<ConsoleData>();
  const { bandwidth_used, bandwidth_max, mechanoids } = data;

  return (
    <Window width={480} height={520} theme="ntos">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="Bandwidth">
              <ProgressBar
                value={bandwidth_used}
                minValue={0}
                maxValue={bandwidth_max}
                ranges={{
                  good: [0, bandwidth_max * 0.5],
                  average: [bandwidth_max * 0.5, bandwidth_max * 0.85],
                  bad: [bandwidth_max * 0.85, bandwidth_max],
                }}
              >
                {bandwidth_used} / {bandwidth_max}
              </ProgressBar>
            </Section>
          </Stack.Item>
          <Stack.Item>
            {mechanoids.length === 0 ? (
              <NoticeBox>No active mechanoids.</NoticeBox>
            ) : (
              mechanoids.map((mech) => (
                <Section
                  key={mech.ref}
                  title={mech.name}
                  buttons={
                    <Box
                      as="span"
                      bold
                      color={mech.piloted ? 'good' : 'average'}
                    >
                      {mech.piloted ? 'Piloted' : 'Autopilot'}
                    </Box>
                  }
                >
                  <ProgressBar
                    value={mech.health}
                    minValue={0}
                    maxValue={100}
                    ranges={{
                      good: [60, 100],
                      average: [30, 60],
                      bad: [0, 30],
                    }}
                  >
                    {mech.health}%
                  </ProgressBar>
                  <Box color="label" mt={1}>
                    Location: {mech.area}. Bandwidth: {mech.bandwidth}.
                    {mech.master ? ` Bonded to ${mech.master}.` : ''}
                  </Box>
                  {!mech.piloted && (
                    <Stack mt={1}>
                      <Stack.Item>
                        <Button
                          icon="location-arrow"
                          onClick={() => act('recall', { ref: mech.ref })}
                        >
                          Recall
                        </Button>
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="ghost"
                          onClick={() => act('offer', { ref: mech.ref })}
                        >
                          Offer to ghosts
                        </Button>
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="trash"
                          color="bad"
                          onClick={() => act('decommission', { ref: mech.ref })}
                        >
                          Decommission
                        </Button>
                      </Stack.Item>
                    </Stack>
                  )}
                </Section>
              ))
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
