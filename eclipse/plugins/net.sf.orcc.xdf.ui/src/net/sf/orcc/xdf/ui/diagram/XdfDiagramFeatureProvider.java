/*
 * Copyright (c) 2013, IETR/INSA of Rennes
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package net.sf.orcc.xdf.ui.diagram;

import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;
import net.sf.orcc.util.OrccLogger;
import net.sf.orcc.xdf.ui.features.CopyFeature;
import net.sf.orcc.xdf.ui.features.DropInstanceFromFileFeature;
import net.sf.orcc.xdf.ui.features.PasteFeature;
import net.sf.orcc.xdf.ui.features.UpdateDiagramFeature;
import net.sf.orcc.xdf.ui.layout.AutoLayoutFeature;
import net.sf.orcc.xdf.ui.patterns.ConnectionPattern;
import net.sf.orcc.xdf.ui.patterns.InputNetworkPortPattern;
import net.sf.orcc.xdf.ui.patterns.InstancePattern;
import net.sf.orcc.xdf.ui.patterns.OutputNetworkPortPattern;
import net.sf.orcc.xdf.ui.util.PropsUtil;

import org.eclipse.core.resources.IFile;
import org.eclipse.graphiti.dt.IDiagramTypeProvider;
import org.eclipse.graphiti.features.IAddFeature;
import org.eclipse.graphiti.features.ICopyFeature;
import org.eclipse.graphiti.features.IFeature;
import org.eclipse.graphiti.features.IPasteFeature;
import org.eclipse.graphiti.features.IReconnectionFeature;
import org.eclipse.graphiti.features.IRemoveFeature;
import org.eclipse.graphiti.features.IUpdateFeature;
import org.eclipse.graphiti.features.context.IAddContext;
import org.eclipse.graphiti.features.context.IContext;
import org.eclipse.graphiti.features.context.ICopyContext;
import org.eclipse.graphiti.features.context.ICustomContext;
import org.eclipse.graphiti.features.context.IPasteContext;
import org.eclipse.graphiti.features.context.IPictogramElementContext;
import org.eclipse.graphiti.features.context.IReconnectionContext;
import org.eclipse.graphiti.features.context.IRemoveContext;
import org.eclipse.graphiti.features.context.IUpdateContext;
import org.eclipse.graphiti.features.context.impl.CreateConnectionContext;
import org.eclipse.graphiti.features.context.impl.ReconnectionContext;
import org.eclipse.graphiti.features.custom.ICustomFeature;
import org.eclipse.graphiti.features.impl.DefaultReconnectionFeature;
import org.eclipse.graphiti.features.impl.DefaultRemoveFeature;
import org.eclipse.graphiti.mm.pictograms.Anchor;
import org.eclipse.graphiti.mm.pictograms.Connection;
import org.eclipse.graphiti.mm.pictograms.Diagram;
import org.eclipse.graphiti.pattern.DefaultFeatureProviderWithPatterns;

import de.cau.cs.kieler.kiml.klayoutdata.KShapeLayout;
import de.cau.cs.kieler.kiml.options.EdgeRouting;
import de.cau.cs.kieler.kiml.options.LayoutOptions;

/**
 * This is a default class, from a new Graphiti project. It should be modified
 * to fit our needs.
 * 
 * @author Antoine Lorence
 * 
 */
public class XdfDiagramFeatureProvider extends
		DefaultFeatureProviderWithPatterns {

	private final PasteFeature pasteFeature;
	private final CopyFeature copyFeature;
	private final UpdateDiagramFeature updateFeature;
	private final DropInstanceFromFileFeature dropInstanceFeature;
	private final ICustomFeature[] layoutFeatures;

	public XdfDiagramFeatureProvider(IDiagramTypeProvider dtp) {
		super(dtp);
		addPattern(new InstancePattern());
		addPattern(new InputNetworkPortPattern());
		addPattern(new OutputNetworkPortPattern());
		addConnectionPattern(new ConnectionPattern());

		copyFeature = new CopyFeature(this);
		pasteFeature = new PasteFeature(this);
		updateFeature = new UpdateDiagramFeature(this);
		dropInstanceFeature = new DropInstanceFromFileFeature(this);

		final ICustomFeature orthogonal = new AutoLayoutFeature(this,
				"Orthogonal routing (default)") {
			@Override
			protected void configureDiagramNode(KShapeLayout diagramLayout) {
				super.configureDiagramNode(diagramLayout);

				diagramLayout.setProperty(LayoutOptions.EDGE_ROUTING,
						EdgeRouting.ORTHOGONAL);
			}
		};

		final ICustomFeature polyline = new AutoLayoutFeature(this,
				"Polyline routing") {
			@Override
			protected void configureDiagramNode(KShapeLayout diagramLayout) {
				super.configureDiagramNode(diagramLayout);

				diagramLayout.setProperty(LayoutOptions.EDGE_ROUTING,
						EdgeRouting.POLYLINE);
			}
		};

		// The first entry is the default
		layoutFeatures = new ICustomFeature[] { orthogonal, polyline };
	}

	/**
	 * Return the default layout feature. It is the first in the layout features
	 * array
	 * 
	 * @return
	 */
	public ICustomFeature getDefaultLayoutFeature() {
		return layoutFeatures[0];
	}

	/**
	 * Return the list of available layout features.
	 * 
	 * @return An array of ICustomFeatures
	 */
	public ICustomFeature[] getLayoutFeatures() {
		return layoutFeatures;
	}

	@Override
	public ICustomFeature[] getCustomFeatures(ICustomContext context) {
		// Custom features are created in XdfDiagramToolBehaviorProvider. This allows to arrange
		// these features in sub-menus
		return super.getCustomFeatures(context);
	}

	@Override
	protected IUpdateFeature getUpdateFeatureAdditional(IUpdateContext context) {
		return updateFeature;
	}

	/**
	 * Implements creation of new connection by dragging instance port.
	 */
	@Override
	public IFeature[] getDragAndDropFeatures(IPictogramElementContext context) {
		return getCreateConnectionFeatures();
	}

	@Override
	public IAddFeature getAddFeature(IAddContext context) {
		if (context.getNewObject() instanceof IFile) {
			return dropInstanceFeature;
		}
		return super.getAddFeature(context);
	}

	@Override
	public ICopyFeature getCopyFeature(ICopyContext context) {
		return copyFeature;
	}

	@Override
	public IPasteFeature getPasteFeature(IPasteContext context) {
		return pasteFeature;
	}

	/**
	 * We never want to remove elements from the diagram. We always want to
	 * delete them. So it is useless to display the menu entry, the button in
	 * the contextual palette. This feature is globally disabled
	 */
	@Override
	public IRemoveFeature getRemoveFeature(IRemoveContext context) {
		return new DefaultRemoveFeature(this) {
			@Override
			public boolean isAvailable(IContext context) {
				return false;
			}
		};
	}

	/**
	 * We want to allow reconnection, even if an existing one is in a bad state.
	 * If the source or target of a connection is a null or non-existing object,
	 * we don't care this is this side the user wants to reconnect.
	 * 
	 * This method also prevent bad connection by reusing logic from
	 * ConnectionPattern.canXXX methods
	 */
	@Override
	public IReconnectionFeature getReconnectionFeature(
			IReconnectionContext context) {
		return new DefaultReconnectionFeature(this) {
			@Override
			public boolean canReconnect(IReconnectionContext context) {
				final Anchor newAnchor = getNewAnchor(context);
				final Connection connection = context.getConnection();

				// Classical checks. Same as original method, without checking
				// null value of start/end in the original connection
				if ((connection == null) || (newAnchor == null)
						|| (newAnchor.getParent() instanceof Diagram)) {
					return false;
				}

				// Delegate to ConnectionPattern to decide if a reconnection can
				// be performed or not
				final ConnectionPattern conPattern = (ConnectionPattern) getConnectionPatterns().get(0);
				final CreateConnectionContext ctxt = new CreateConnectionContext();
				if (context.getReconnectType().equals(ReconnectionContext.RECONNECT_TARGET)) {
					ctxt.setSourceAnchor(connection.getStart());
					ctxt.setTargetAnchor(newAnchor);
					return conPattern.canCreate(ctxt);
				} else {
					ctxt.setSourceAnchor(newAnchor);
					ctxt.setTargetAnchor(connection.getEnd());
					return conPattern.canStartConnection(ctxt);
				}
			}

			@Override
			public void postReconnect(IReconnectionContext context) {

				// On reconnection, we have to update the business model object
				// source or target
				final net.sf.orcc.df.Connection dfConnection = (net.sf.orcc.df.Connection) getBusinessObjectForPictogramElement(context
						.getConnection());
				final Anchor newAnchor = context.getNewAnchor();
				final Vertex vertex = (Vertex) getBusinessObjectForPictogramElement(newAnchor
						.getParent());

				if (context.getReconnectType().equals(
						ReconnectionContext.RECONNECT_SOURCE)) {

					if (PropsUtil.isInputPort(newAnchor.getParent())) {
						dfConnection.setSource(vertex);
						dfConnection.setSourcePort(null);

					} else if (PropsUtil.isInstanceOutPort(newAnchor)) {
						dfConnection.setSource(vertex);
						final Port port = (Port) getBusinessObjectForPictogramElement(newAnchor);
						dfConnection.setSourcePort(port);
					} else {
						OrccLogger
								.severeln("Unable to get the new source type.");
					}
				} else {
					if (PropsUtil.isOutputPort(newAnchor.getParent())) {
						dfConnection.setTarget(vertex);
						dfConnection.setTargetPort(null);

					} else if (PropsUtil.isInstanceInPort(newAnchor)) {
						dfConnection.setTarget(vertex);
						final Port port = (Port) getBusinessObjectForPictogramElement(newAnchor);
						dfConnection.setTargetPort(port);
					} else {
						OrccLogger
								.severeln("Unable to get the new target type.");
					}
				}
			}
		};
	}
}
